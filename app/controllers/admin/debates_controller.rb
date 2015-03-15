# Controlador par la administración de propuestas del gobierno (debates).
class Admin::DebatesController < Admin::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_debate_tag_list_without_hashtag, :auto_complete_for_debate_entity_organization_name]

  before_filter :set_form_lang, :only => [:new, :edit, :create, :update]
  before_filter :get_debate, :except => [:index, :arguments, :new, :create, :auto_complete_for_debate_tag_list_without_hashtag, :auto_complete_for_debate_entity_organization_name]

  uses_tiny_mce :only => [:new, :create, :edit, :edit_common, :update],
                :options => TINYMCE_OPTIONS

  def index
    @debates = Debate.paginate(:page => params[:page], :per_page => 20)
      .reorder("(CASE WHEN coalesce(featured, 'f')<>'f' OR featured_bulletin<>'f' then extract(epoch from now()+'30days'::interval) else extract(epoch from coalesce(published_at, now()-'1hour'::interval)) end) DESC")
    @title = t("admin.debates.propuestas_del_gobierno")
  end

  def arguments
    @title = t("admin.debates.propuestas_del_gobierno")
    @arguments = Argument.for_debates.joins("INNER JOIN users ON (users.id = arguments.user_id) ")
      .paginate(:per_page => 20,:page => params[:page]).reorder("published_at DESC, created_at DESC")
  end

  def new
    @title = t("admin.debates.crear_propuesta_gubernamental")
    get_departments()
    @debate = Debate.new
    @debate.init_stages
  end

  def edit
    @title = t("admin.debates.modificar_propuesta_gubernamental")
    if params[:w].eql?("traducciones")
      @show_only_translatable = true
    else
      get_departments()
    end
  end

  def create
    @title = t("admin.debates.crear_propuesta_gubernamental")
    @debate = Debate.new(debate_params)
    if @debate.save
      flash[:notice] = 'La propuesta se ha guardado correctamente'
      redirect_to admin_debate_path(@debate)
    else
      get_departments()
      render :action => 'new'
    end
  end

  def update
    # @debate.attributes = debate_params

    @title = t("admin.debates.actualizar_propuesta_gubernamental")

    if @debate.update_attributes(debate_params)
      flash[:notice] = 'Los cambios se han guardado correctamente'
      redirect_to params[:redirect_to] || admin_debate_path(@debate)
    else
      get_departments()
      render :action => params[:return_to] || 'edit'
    end
  end

  def show
  end

  def destroy
    @title = t("admin.debates.eliminar_propuesta_gubernamental")

    if @debate.destroy
      flash[:notice] = 'La propuesta se ha eliminado correctamente'
      redirect_to admin_debates_path
    else
      flash[:error] = 'La propuesta no se ha podido eliminar'
      redirect_to admin_debate_path(@debate)
    end
  end

  def common
  end

  def edit_common
  end

  def translations
    @t = "debate"
  end

  def auto_complete_for_debate_tag_list_without_hashtag
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:debate][:tag_list_without_hashtag])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end
  end

  def auto_complete_for_debate_entity_organization_name
    q = params[:debate_entity][:organization_name].strip.tildes.downcase

    @organizations = OutsideOrganization.where(["(lower(tildes(name_es || coalesce(name_eu, '') || coalesce(name_en, ''))) like ?)", "%#{q}%"])
    if @organizations.length > 0
      render :inline => '<%= content_tag(:ul, @organizations.map {|o| content_tag(:li, "#{o.name}")}.join.html_safe) %>'
    else
      render :nothing => true
    end
  end

  def publish
    @debate.update_attributes(:published_at => Time.zone.now)
    redirect_to :back
  end

  private

  def set_form_lang
    @lang = (params[:lang] || "es").to_sym
  end

  def set_current_tab
    @current_tab = :debates
  end

  def get_debate
    @debate = Debate.find(params[:id])
    @title = @debate.title
  end

  # Lista de departamentos para el select:
  # para debates nuevos, salen sólo los departamentos activos
  # para debates con departamento que ya no es activo, salen todos los departamentos.
  def get_departments
    @departments = if @debate && @debate.organization && !@debate.organization.active?
      Department.order("position")
    else
      Department.active.reorder("position")
    end
  end

  def debate_params
    params.require(:debate).permit(:organization_id, :hashtag, :title_es, :title_eu, :title_en, 
      :body_es, :body_eu, :body_en, :description_es, :description_eu, :description_en, :draft, 
      :tag_list_without_hashtag, :multimedia_dir, :featured, :featured_bulletin, :cover_image, :remove_cover_image,
      :header_image, :remove_header_image, :stages_attributes => [:active, :_destroy, :starts_on, :ends_on, :label, :id])
  end

end
