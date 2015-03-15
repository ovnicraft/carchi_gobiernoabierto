# Controlador para la gestión simplificada de noticias.
# Aquí está la gestión de las funciones que pueden realizar los usuarios de tipo
# DepartmentMember, DepartmentEditor y StaffChief. Funciones para los administradores
# generales están en Admin::DocumentsController
class Sadmin::NewsController < Sadmin::BaseController
  before_filter :access_to_news_required, :except => :home
  before_filter :news_create_required, :only => [:new, :create, :destroy]
  before_filter :get_news, :only => [:show, :edit, :edit2, :edit_tags, :update]
  before_filter :news_export_required, :only => [:published]

  uses_tiny_mce :only => [:new, :create, :edit, :update],
                :options => Admin::BaseController::TINYMCE_OPTIONS

  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_news_tag_list, :auto_complete_for_news_politicians_tag_list]
  auto_complete_for :news, :tag_list

  # Página home de la administración. Redirige a una pestaña diferente en función
  # del perfil y las funciones del usuario
  def home
    if (logged_in? && can_access?("news"))
      if current_user.is_a?(StaffChief)
        redirect_to sadmin_events_path
      else
        redirect_to sadmin_news_index_path
      end
    elsif logged_in? && can_access?("events")
      redirect_to sadmin_events_path
    elsif logged_in? && current_user.is_a?(StreamingOperator)
      redirect_to admin_stream_flows_path
    elsif logged_in? && current_user.is_a?(RoomManager)
      redirect_to sadmin_account_path
    else
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Listado de noticias
  def index
    @sort_order = params[:sort] ||  "publish"

    case @sort_order
    when "update"
      order = "updated_at DESC, title_es, published_at DESC"
    when "publish"
      order = "(CASE WHEN featured IS NOT NULL OR featured_bulletin<>'f' THEN extract(epoch from now()+'30days'::interval) ELSE extract(epoch from coalesce(published_at, now()-'1hour'::interval)) END) DESC"
    when "title"
      order = "lower(tildes(title_es)), published_at DESC, updated_at DESC"
    end

    conditions = nil
    if params[:q].present?
      conditions = ["lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like ?", "%#{params[:q].tildes.downcase}%"]
    end

    set_current_tab

    @news = News.where(conditions).paginate(:page => params[:page], :per_page => 20).reorder(order)
    @title = t("news.title")
  end

  # Vista de una noticia
  def show
    set_current_tab
  end

  # Formulario de nueva noticia
  def new
    @t = params[:t] || 'doc'
    @title = t('sadmin.news.crear_noticia')
    @news = News.new

    @news.multimedia_dir = @news.default_multimedia_dir

    if current_user.has_department?
      @news.organization_id = current_user.department_id
    end

    if params[:related_event_id] && (event = Event.find(params[:related_event_id]))
      @news.event_ids = [event.id]
      ['organization_id', 'title', 'speaker', 'area_tags', 'politicians_tag_list'].each do |method|
        @news.send("#{method}=", event.send(method))
      end
      @news.multimedia_dir = event.starts_at.to_date.to_s.gsub('-', '/') + '/'
    end

    if params[:debate_id] && (@debate = Debate.find(params[:debate_id]))
      ["title_es", "title_eu", "title_en", "tag_list", "organization_id"].each do |m|
        @news.send("#{m}=", @debate.send(m))
      end
      @news.debate = @debate
      @news.multimedia_dir += "propgob_#{@debate.multimedia_dir}"
    end
    set_current_tab
  end

  # Creación de nueva noticia
  def create
    set_current_tab
    @title = t('sadmin.news.crear_noticia')
    @news = News.new(news_params)

    if @news.event_ids.first
      if event = Event.find(@news.event_ids.first)
        ['title', 'speaker'].each do |m|
          locales.each do |code, loc|
            @news.send("#{m}_#{code}=", event.send("#{m}_#{code}")) if @news.send("#{m}_#{code}").blank?
          end
        end
        # Los tags de político se asignan a través de politicians_tag_list= y el de área con area_tags=
        @news.tag_list.add((event.tags - event.politicians_tags - event.areas.collect(&:area_tag)).map(&:name))
      end
    end

    if @news.debate.present?
      # Si la noticia corresponde a las conclusiones de un debate,
      # copiamos los tags del debate menos el del área como tags de la noticia.
      # El tag del área ya está asignado a través del formulario.
      @news.tag_list.add((@news.debate.tags - @news.debate.areas.collect(&:area_tag)).map(&:name))
    end

    if @news.save
      flash[:notice] = t('sadmin.guardado_correctamente', :article => News.model_name.human.gender_article, :what => News.model_name.human)
      redirect_to sadmin_news_path(@news.id)
    else
      render :action => 'new'
    end
  end

  # Modificación de una noticia
  def edit
    set_current_tab
    @title = t('sadmin.modificar_what', :what => t('news.title'))
  end

  # Actualización de una noticia
  def update
    # @news.attributes = params[:news]
    set_current_tab
    @title = t('sadmin.modificar_what', :what => t('news.title'))

    if @news.update_attributes(news_params)
      flash[:notice] = t('sadmin.guardado_correctamente', :article => News.model_name.human.gender_article, :what => News.model_name.human)
      redirect_to sadmin_news_path(@news.id)
    else
      render :action => params[:return_to] || 'edit'
    end
  end

  # Eliminación de una noticia
  def destroy
    @news = News.find(params[:id])
    set_current_tab

    if @news.destroy
      flash[:notice] = t('sadmin.eliminado_correctamente', :article => t('news.title').gender_article, :what => t('news.title'))
      redirect_to sadmin_news_index_path
    else
      flash[:error] = t('sadmin.no_eliminado_correctamente', :article => t('news.title').gender_article, :what => t('news.title'))
      redirect_to sadmin_news_path(@news.id)
    end
  end

  # Devuelve los tags que coinciden con el string buscado en el auto complete
  def auto_complete_for_news_tag_list
    auto_complete_for_tag_list(params[:news][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.nombre)}) %>"
    else
      render :nothing => true
    end
  end

  #
  # Autocomplete para la lista de políticos
  #
  def auto_complete_for_news_politicians_tag_list
    auto_complete_for_document_politicians_tag_list(params[:news][:politicians_tag_list])
  end

  # Listado de todas las noticias publicadas, para elegir las que se quieren exportar
  def published
    @news = News.published.paginate(:per_page => 30, :page => params[:page]).reorder("published_at DESC")

    # Borramos las que no estan publicadas en ningun idioma
    @news.to_a.delete_if {|n| Document::LANGUAGES.collect {|l| n.translated_to?(l)}.uniq == [false]}
  end

  def new_epub
    @criterio=Criterio.find(params[:criterio_id])
     results = Elasticsearch::Base::do_elasticsearch_with_facets(@criterio, 0, nil, false, I18n.locale, 301)

     if results.empty?
       redirect_to elasticsearch_not_available_redirect_url and return
     elsif results['total_hits']>300
       flash[:notice] = "Por motivos técnicos, debes hacer una búsqueda con un máximo de 300 noticias."
       redirect_to choose_criterio_sadmin_news_index_path and return
     end
     @search_results=results['hits']

     @search_results.delete_if {|s| !s.is_a?(News)}
  end

  def create_epub
    generator = EpubGenerator.new
    zip_file_path = generator.export(params[:news_to_export], params[:export_dir])
    send_file(zip_file_path)
  end

  private

  # Coge los datos de la noticia
  def get_news
    @news = News.find(params[:id])
  end

  # Determina el tab del menú que está activo
  def set_current_tab
    @current_tab = :news
  end

  # Filtro para determinar si el usuario puede acceder a la gestión de las noticias
  def access_to_news_required
    unless (logged_in? && can_access?("news"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario puede crear noticias
  def news_create_required
    unless (logged_in? && can_create?("news"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario puede crear noticias
  def news_export_required
    unless (logged_in? && can?("export", "news"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def news_params
    params.require(:news).permit(:organization_id, :politicians_tag_list, :speaker_es, :speaker_eu, :speaker_en, 
      :title_es, :title_eu, :title_en, :body_es, :body_eu, :body_en, :cover_photo, :delete_cover_photo, :cover_photo_alt_es, 
      :cover_photo_alt_eu, :cover_photo_alt_en, :multimedia_dir, :consejo_news_id, :draft, :published_at, :debate_id,
      :event_ids => [], :area_tags=> [])
  end
  
end
