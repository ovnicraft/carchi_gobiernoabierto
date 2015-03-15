# Controlador para la administración de acciones comunes de News, Event, Page
class Admin::DocumentsController < Admin::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_document_tag_list_without_areas]

  skip_before_filter :admin_required

  before_filter :edit_info_required, :only => [:index, :show, :edit, :edit_tags, :update, :auto_complete_for_document_tag_list_without_areas, :publish]

  before_filter :create_info_required, :only => [:new, :create, :update_comments_status, :destroy, :comments]

  before_filter :page_create_info_required, :only => [:new, :create]

  before_filter :get_document, :only => [:show, :edit, :edit2, :edit_tags, :update, :destroy, :publish]

  uses_tiny_mce :only => [:new, :create, :edit, :update], :options => TINYMCE_OPTIONS

  auto_complete_for :document, :tag_list_without_areas

  # Formulario de nueva página
  def new
    @t = params[:t] || 'doc'
    @title = t('sadmin.create_what', :what => @pretty_type)
    @document = @t.singularize.camelize.constantize.new

    set_current_tab

    if params[:debate_id].present?
      if @debate = Debate.find(params[:debate_id])
        ["title_es", "title_eu", "title_en", "tag_list", "organization_id"].each do |m|
          @document.send("#{m}=", @debate.send(m))
        end
        @document.multimedia_dir = "cont_#{@debate.multimedia_dir}"
        @document.debate = @debate
      end
    end
  end

  # Creación de nueva página
  def create
    set_current_tab
    @title = t('sadmin.create_what', :what => @pretty_type)
    @document = @t.singularize.camelize.constantize.new(document_params_for_create)
    @debate = @document.debate

    if @document.save
      flash[:notice] = t('sadmin.guardado_correctamente', :article => t('documents.document').gender_article, :what => t('documents.Document'))
      redirect_to admin_document_path(@document.id)
    else
      render :action => 'new'
    end
  end

  # Listado de páginas
  def index
    @sort_order = params[:sort] ||  "update"
    
    case @sort_order
    when "update"
      order = "updated_at DESC, title_es, published_at DESC"
    when "publish"
      order = "published_at DESC, title_es, updated_at DESC"
    when "title"
      order = "lower(tildes(title_es)), published_at DESC, updated_at DESC"
    end
    
    conditions = []
    if params[:q].present?
      conditions << "lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like '%#{params[:q].tildes.downcase}%'"
    end

    set_current_tab    
    
    if @t.eql?("news")
      redirect_to sadmin_news_index_path and return 
    elsif (["event", "events"].include?(@t))
      redirect_to sadmin_events_path and return 
    end

    @documents = @t.singularize.camelize.constantize.where(conditions.join(' AND '))
        .paginate(:page => params[:page], :per_page => 20).reorder(order)

    @title = t("#{@t.tableize}.title")
  end

  # Vista de información adicional de una noticia, página o evento
  def show
    check_access
    @w = params[:w] || "multimedia"
    if (@w.eql?("multimedia") && !can?("complete", "news")) || (@w.eql?("more_info") && !is_admin?)
      flash[:error] = "No puedes acceder a estas páginas"
      redirect_to admin_document_path(@document.id, :w => "traducciones") and return
    end
    @title = "#{@document.title}"
    set_current_tab
  end

  # Formulario de modificación de una página
  def edit
    check_access
    set_current_tab
    @title = t('sadmin.modificar_what', :what => @pretty_type)
  end
    
  # Modificación de la información adicional de una noticia, evento, página
  def edit_tags
    check_access
    if (@document.is_a?(News) && !can?("complete", "news")) || (@document.is_a?(Event) && !is_admin?)
      flash[:error] = "No puedes acceder a estas páginas"
      redirect_to admin_document_path(@document.id, :w => "traducciones") and return
    end
    set_current_tab
    @w = params[:w] || "multimedia"
    @title = t('sadmin.modificar_what', :what => @pretty_type)
    
    if @document.is_a?(Event)
      @overlap_events_with_streaming = @document.overlapped_streaming 
    end
  end

  # Modificación de la información adicional de una noticia, evento, página
  def update
    check_access
    set_current_tab
    @title = t('sadmin.modificar_what', :what => @pretty_type)
    if @document.update_attributes(document_params)
      flash[:notice] = t('sadmin.guardado_correctamente', :article => @document.class.model_name.human.gender_article, :what => @document.class.model_name.human)
      if @document.respond_to?('draft_news') && @document.draft_news.to_i.eql?(1) && @document.is_a?(Event) && !@document.has_related_news?
        redirect_to new_sadmin_news_path(:related_event_id => @document.id)
      else
        redirect_to admin_document_path(@document.id, :w => params[:w])
      end
    else
      if @document.is_a?(Event)
        @overlap_events_with_streaming = @document.overlapped_streaming 
      end
      render :action => params[:return_to] || 'edit'
    end
  end

  # Eliminación de una noticia, evento, página
  def destroy
    check_access
    set_current_tab

    if @document.destroy
      flash[:notice] = t('sadmin.eliminado_correctamente', :article => @document.class.model_name.human.gender_article, :what => @document.class.model_name.human)
      if @t.eql?("news")
        redirect_to sadmin_news_index_path and return 
      else
        redirect_to admin_documents_path(:t => @t)
      end
    else
      flash[:error] = t('sadmin.no_eliminado_correctamente', :article => @document.class.model_name.human.gender_article, :what => @document.class.model_name.human)
      redirect_to :back
    end
  end

  # Auto complete para los tags
  def auto_complete_for_document_tag_list_without_areas
    # ANTES: auto_complete_for_tag_list(params[:document][:tag_list_without_areas])
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:document][:tag_list_without_areas])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end
  end

  # Marca una página como publicada
  def publish
    check_access
    @document.update_attributes(:published_at => Time.zone.now)
    redirect_to :back
  end

  private

  # Coge la información de la página/evento/noticia
  def get_document
    @document = Document.find(params[:id])
    # @t = @document.type.to_s.downcase.pluralize.to_sym
  end

  # Determina el tab del menú activo en función del tipo de contenido
  def set_current_tab
    @t = @document ? @document.class.to_s.downcase.pluralize : (params[:t].present? ? params[:t] : 'news')
    @pretty_type = @t.titleize.singularize.constantize.model_name.human

    @current_tab = @t.to_sym
    @current_tab
  end

  # Filtro para determinar si el usuario puede editar la página
  def page_edit_info_required
    unless (logged_in? && can_edit?("pages"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario puede crear una página
  def page_create_info_required
    unless (logged_in? && can_create?("pages"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario puede editar la página/noticia/evento
  def check_access
    has_access = case 
    when @document.is_a?(News)
      can_edit?("news") || can?("complete", "news")
    when @document.is_a?(Event)
      can_edit?("events")
    else
      can_edit?("pages")
    end
    unless has_access
      flash[:notice] = t('no_tienes_permiso')
      access_denied      
    end
  end

  # Filtro para determinar si el usuario puede editar la página/noticia/vento
  def edit_info_required
    unless can_edit?("news") || can_edit?("events") || can_edit?("pages") || can?("complete", "news")
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario puede crear la página/evento/noticia
  def create_info_required
    unless can_create?("news") || can_create?("events") || can_create?("pages")
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def document_params_for_create
    params.require(:document).permit(:title_es, :body_es, :multimedia_dir, :draft, :published_at,
      :organization_id, :tag_list_without_areas, :debate_id)
  end

  def document_params
    if @document.is_a?(News)
      params.require(:document).permit(:tag_list_without_areas, :featured, :featured_bulletin, :comments_closed, 
      :multimedia_dir, :title_eu, :speaker_eu, :cover_photo_alt_eu, :body_eu, :title_en, :speaker_en, 
      :cover_photo_alt_en, :body_en, :title_es, :speaker_es, :cover_photo_alt_es, :body_es, :area_tags => [])
    elsif @document.is_a?(Event)
      params.require(:document).permit(:tag_list_without_areas, :comments_closed, 
      :multimedia_dir, :irekia_coverage, :irekia_coverage_photo, :irekia_coverage_video, :irekia_coverage_audio, 
      :irekia_coverage_article, :streaming_for_irekia, :streaming_for_en_diferido, :streaming_live, :stream_flow_id, 
      :alert_this_change, :draft_news, :title_es, :body_es, :title_eu, :body_eu, :title_en, :body_en, :area_tags => [])
    elsif @document.is_a?(Page)      
      params.require(:document).permit(:tag_list_without_areas, :organization_id, :multimedia_dir, :draft, :published_at,
        :title_es, :body_es, :title_eu, :body_eu, :title_en, :body_en)
    end    
  end

end
