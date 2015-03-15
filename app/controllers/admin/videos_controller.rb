# Controlador para la administración de videos de la WebTV
class Admin::VideosController < Sadmin::BaseController
  before_filter :access_to_web_tv_required
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_video_tag_list]
  
  cache_sweeper :video_sweeper, :only => [:create, :update]
  
  # Listado de videos
  def index
    @sort_order = params[:sort] ||  "update"
    
    case @sort_order
    when "update"
      order = "featured DESC, updated_at DESC, title_es, published_at DESC"
    when "publish"
      order = "featured DESC, published_at DESC, title_es, updated_at DESC"
    when "title"
      order = "featured DESC, lower(tildes(title_es)), published_at DESC, updated_at DESC"
    end
    
    conditions = []
    if params[:q].present?
      conditions << "lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like '%#{params[:q].tildes.downcase}%'"
    end   

    @videos = Video.where(conditions.join(' AND '))
      .paginate(:page => params[:page], :per_page => 20).reorder(order)
      
    @title = "Videos"
    
  end

  # Vista de un video
  def show
    @video = Video.find(params[:id])
    @title = @video.title
  end

  # Formulario de nuevo video
  def new
    @title = "Nuevo video"
    @video = Video.new
  end
  
  # Crear un video
  def create
    @title = "Crear video"
    @video = Video.new(video_params)
    
    if @video.save
      flash[:notice] = 'El video se ha guardado correctamente'
      redirect_to admin_video_path(@video)
    else
      render :action => 'new'
    end
  end

  # Modificar un video
  def edit
    @title = "Modificar video"
    @video = Video.find(params[:id])
  end
  
  # Actualizar un video
  def update
    @video = Video.find(params[:id])
    
    if @video.update_attributes(video_params)
      flash[:notice] = 'El documento se ha guardado correctamente'
      redirect_to admin_video_path(@video)
    else
      render :action => params[:return_to] || 'edit'
    end
  end

  # Gestión de los subtítulos
  
  # Importar el vídeo y subir el fichero con los subtítulos.
  # El vídeo se importa a la webTV de la misma manera de la que se hace desde el rake task.
  # La visibilidad del vídeo en los diferentes idiomas se "decide" a partir de los fichero subidos 
  # y el fichero SRT ue se sube ya tiene indicado a qúé idioma pertenece.
  def create_with_subtitles
    if document = Document.find(params[:video][:document_id])
      flv_url = params[:video].delete(:flv_url)
      video_path = flv_url.sub(/^#{Document::MULTIMEDIA_URL}/, '').sub(/(_es|_eu|_en)*.flv$/, '').sub(/^\//,'')
      visibility = lang_visibility(video_path)
      current_video_params = {:video_path => video_path,
                      :show_in_es => visibility[:es], 
                      :show_in_eu => visibility[:eu], 
                      :show_in_en => visibility[:en],
                      :title_es => document.title_es, 
                      :title_eu => document.title_eu || document.title_es, 
                      :title_en => document.title_en || document.title_es, 
                      :published_at => document.published_at}
      
      @video = document.webtv_videos.build(video_subtitle_params.merge(current_video_params))
      if @video.save
        flash[:notice] = t('sadmin.subtitles.video_con_subtitulos_creado')
      else
        logger.error "ERROR admin/videos/create_with_subtitles: #{@video.errors.inspect}"
        flash[:error] = t('sadmin.subtitles.video_con_subtitulos_no_creado')
      end
      redirect_to sadmin_news_subtitles_path(:news_id => document.id)
    else
      flash[:error] = t('sadmin.subtitles.no_hemos_encontrado_el_documento')
      redirect_to default_url_for_user
    end
  end
   
  # Subir/sustituir el fichero con los subtítulos en un idioma
  def update_subtitles
    @video = Video.find(params[:id])
    
    unless @video.document
      flash[:error] = t('sadmin.subtitles.solo_se_pueden_subir_subtitulos_para_documento')
      redirect_to admin_video_path(@video) and return
    end
    
    if @video.update_attributes(video_subtitle_params)
      flash[:notice] = t('sadmin.subtitles.fichero_guardado')
    else
      logger.error "ERROR admin/videos/update_subtitles: #{@video.errors.inspect}"
      flash[:error] = t('sadmin.subtitles.fichero_no_guardado')
    end
    redirect_to sadmin_news_subtitles_path(:news_id => @video.document_id)
  end

  # Eliminar el SRT para un idioma concreto
  def delete_subtitles
    @video = Video.find(params[:id])
    
    unless @video.document
      flash[:error] = t('sadmin.subtitles.solo_se_pueden_gestionar_videos_con_documento')
      redirect_to admin_video_path(@video) and return
    end
    
    lang = params[:lang]
    if s = @video.respond_to?("subtitles_#{lang}")
      @video.send("subtitles_#{lang}=", nil) 
      if @video.save
        flash[:notice] = t('sadmin.subtitles.fichero_eliminado')
      else
        logger.error "ERROR admin/videos.delete_subtitles: #{@video.errors.inspect}"
        flash[:error] = t('sadmin.subtitles.fichero_no_eliminado')
      end
    end
    
    redirect_to sadmin_news_subtitles_path(:news_id => @video.document_id)
  end
  # /Subtítulos
  
  def publish
    @video = Video.find(params[:id])
    @video.update_attributes(:published_at => Time.zone.now)
    redirect_to :back
  end

  # Eliminar un video
  def destroy
    @video = Video.find(params[:id])
    if @video.destroy
      flash[:notice] = "El video ha sido eliminado"
      redirect_to admin_videos_path
    else
      flash[:error] = "No hemos podido eliminar el video"
      redirect_to admin_video_path(@video)
    end
  end
  
  # Buscar el video en la ruta especificada
  def find_video
    @video = Video.new(:video_path => params[:video_path])
  end
  
  # Lista de tags para el auto-complete
  def auto_complete_for_video_tag_list
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:video][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end  
  end
  
  # Canales de la WebTV
  def channels
    @tree = Tree.find_videos_tree
    @title = "#{@tree.name_es} / #{@tree.name_eu}"
  end

  private
  def set_current_tab
    @current_tab = :videos
  end
  
  def access_to_web_tv_required
    unless (logged_in? && can_access?("videos"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # La misma función que se usa en el rake task include_new_videos_in_webtv
  def lang_visibility(path)
    {:es => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv"))), 
     :eu => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv"))), 
     :en => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")))}
  end
  
  def video_params
    params.require(:video).permit(:title_es, :title_eu, :title_en, :video_path, :tag_list, :featured, 
      :draft, :published_at, :show_in_es, :show_in_eu, :show_in_en)
  end

  def video_subtitle_params
    params.require(:video).permit(:document_id, :flv_url, :subtitles_es, :subtitles_eu, :subtitles_en)
  end
end
