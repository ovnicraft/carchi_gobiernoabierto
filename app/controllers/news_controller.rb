# Controlador para la parte pública de las noticias.
class NewsController < ApplicationController
  # Asigna la variable @context que puede ser un área, un político o nil
  before_filter :get_context, :only => [:index]
  before_filter :get_criterio, :only => [:show]
  before_filter :get_full_width_param, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]

  def index
    prepare_news(@context, request.xhr?)

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @news, :type => 'news'}, :layout => false
        else
          render
        end
      end
      format.rss do
        @feed_title = t('documents.feed_title', :name => @context ? @context.name : Settings.site_name)
        render :layout => false
      end
    end
  end

  def summary
    @leading_news = News.featured_a
    @secondary_news = News.featured_4b
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end

  # Vista de una noticia
  def show
    begin
      @document = News.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if can_edit?("news")
        @document = News.find(params[:id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    @title = @document.title

    # @parent = @document
    @comments = @document.all_comments.approved.paginate :page => params[:page], :per_page => 25

    # Mostramos todos los vídeos de la noticia
    get_news_videos_and_photos(@document)
    @videos_mpg = @document.videos_mpg

    respond_to do |format|
      format.html { render }
      format.xml
      format.floki { render }
    end
  end

  # Devuelve un archivo zip con todas las fotos o vídeos del documento
  def compress
    @news = News.published.find(params[:id])
    @w = params[:w] && @news.respond_to?(params[:w]) ? params[:w] : 'photos'
    if @news.send("zip_#{@w}", I18n.locale)
      send_file(@news.send("zip_#{@w}_file_#{I18n.locale}"))
    else
      flash[:error] = t('documents.error_zip')
      redirect_to news_url(:id => @news.id)
    end
  end

  # Devuelve una imagen de una noticia, generando el tamaño solicitado por el camino si este no existe ya
  def image
    if params[:path].present? && params[:size].present?
      file_to_send = get_or_generate_desired_image(params[:path], params[:size])
      send_file(file_to_send, :type => 'image/jpeg', :disposition => 'inline')
    else
      render :nothing => true
    end
  end

  # RSS para las noticias de cada departamento
  def department
    @department = Department.find(params[:id])
    @feed_title = t('documents.feed_title', :name => @department.name)
    organization_ids = [@department.id] + @department.organization_ids
    @documents = News.published.translated
      .where("organization_id in (#{organization_ids.join(',')})").limit(10).reorder('published_at DESC')
    respond_to do |format|
      format.rss
    end
  end

  def organization
    @organization = Organization.find(params[:id])
    @feed_title = t('documents.feed_title', :name => @organization.name)
    @documents = News.published.translated
      .where("organization_id = #{@organization.id}").limit(10).reorder('published_at DESC')
    respond_to do |format|
      format.rss
    end
  end

  private

  def make_breadcrumbs
    if @context
      @breadcrumbs_info << [t('news.title'), send("#{@context.class.to_s.downcase}_news_path", @context)]
      if @document && !@document.new_record?
        @breadcrumbs_info << [@document.title, send("#{@context.class.to_s.downcase}_news_path", @context, @document)]
      end
    else
      @breadcrumbs_info = [[t('news.title'), news_index_path]]
      if @document && !@document.new_record?
        @breadcrumbs_info << [@document.title,  news_path(@document)]
      end
    end
    @breadcrumbs_info
  end

  # Las imágenes de la galería de una noticia se suben al servidor a través de SFTP,
  # por lo que los diferentes tamaños no se pueden generar en el momento de subirlas.
  # Por eso se generan en el momento que se piden por HTTP por primera vez, y luego
  # se sirve la que ya está generada.
  def get_or_generate_desired_image(path, size="n70")
    sanitized_path = path.gsub(/[^a-z0-9_\-\/\.]/i, '')
    size = "n70" if size.blank?

    orig_file = File.join(Document::MULTIMEDIA_PATH, sanitized_path)

    logger.info "get_or_generate_desired_image. Quiero #{orig_file}, size=#{size}"

    case
    when Tools::Multimedia::PHOTOS_SIZES.keys.include?(size.to_sym)
      file_to_send = Tools::PhotoUtils.photo_size_path(orig_file, size)
    else
      logger.info "El tamaño no es correcto."
      file_to_send = orig_file
    end

    if !File.exists?(file_to_send)
      begin
        IrekiaThumbnail.make(orig_file, Tools::Multimedia::PHOTOS_SIZES[size.to_sym], size)
      rescue IrekiaThumbnailError => err
        logger.error err
        file_to_send = File.join(Rails.root, 'public', 'uploads', 'sample.jpg')
      end
    else
      logger.info "get_or_generate_desired_image: Esta imagen ya existe."
    end
    return file_to_send
  end

end
