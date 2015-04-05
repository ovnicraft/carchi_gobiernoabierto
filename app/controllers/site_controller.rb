# Controlador para paginas del site en general
class SiteController < ApplicationController
  skip_before_filter :set_locale, :only => [:splash, :change_locale, :show, :setup, :update_setup]
  before_filter      :setup_admin_required, :only => [:setup, :setup2, :update_setup]
  layout             'setup', :only => [:setup, :setup2, :update_setup]

  def show
    respond_to do |format|
      format.html do
        if !Settings.customized
          flash[:notice] = "Por favor, conéctate con la cuenta de administrador para configurar los parámetros básicos de tu Open Irekia como el nombre, logo, y dirección de correo."
          redirect_to setup_site_path
        elsif params[:locale].blank? && cookies['locale'].blank?
          redirect_to lang_path
        else
          set_locale
          @carousel_news = ([News.featured_a] + News.featured_4b).compact
          @streaming = Streaming.new
          @debates = (Debate.published.featured + Debate.published.order("published_at DESC").limit(4))[0..3]
          @albums = Album.with_photos.featured.limit(4)
          @videos = Video.published.translated.order("featured DESC, published_at DESC").limit(4)
          render
        end
      end
    end
  end

  # Redirect to new search controller
  def search
    redirect_to get_create_search_index_url(:key => 'keyword', :value => params[:q], :new => true)
  end


  # Página para errores 404 de página no encontrada
  def notfound
    if params[:path].include?("embed")
      service_unavailable
    else
      render(:status => "404 Not Found" )
    end
  end

  def contact
    @title = t('site.contactar')
    @breadcrumbs_info = [[@title, contact_site_path]]
    respond_to do |format|
      format.html
    end
  end

  # Envío de sugerencia al administrador
  def send_contact
    @title = t('site.contactar')
    if params[:name].blank? || params[:email].blank? || params[:message].blank?
      @form_errors = [['name', t('activerecord.errors.messages.blank')], ['message', t('activerecord.errors.messages.blank')], ['email', t('activerecord.errors.messages.blank')]]
      # flash[:error] = t('share.todos_campos')
      render :action => "contact" and return
    elsif !params[:email].match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
      # flash[:error] = t('share.email_incorrecto')
      @form_errors = [['email', t('share.email_incorrecto')]]
      render :action => "contact" and return
    end

    begin
      logger.info("Mandando email de contacto")
      Notifier.contact(params[:name], params[:email], params[:message]).deliver
      @title =  t('site.contacto_enviado')
      @message = t('site.body_contacto_enviado')
    rescue Net::SMTPServerBusy, Net::SMTPSyntaxError => err_type
      logger.info("Error al mandar mail de pagina: " + err_type)
      flash[:error] = t('session.Error_servidor_correo')
      @message = t('site.body_contacto_no_enviado')
    end
  end

  # Página para que un robot monitorice y compruebe que el site no se ha caido.
  def stat
    @app_stat = "OK"
    begin
      ActiveRecord::Base.connection.execute("SELECT 1 FROM documents")
      @db_stat = "OK"
    rescue
      @db_stat = "KO"
    end
    render :layout => false
  end

  # Página splash para la elección del idioma
  def splash
    if Settings.customized
      respond_to do |format|
        format.html {
          # desactivado el multi idioma y forzado el uso de español
          #if cookies['locale'].blank? || request.url.eql?(lang_path)
          #  render :layout => false
          #else
          #  redirect_to "/#{cookies['locale']}"
          #end
          redirect_to "/es"
        }
      end
    else
      redirect_to setup_site_path
    end
  end

  def setup
    @corporative = Corporative.new
    render :action => "setup"
  end

  def setup2
    @corporative = Corporative.new
    render :action => "setup2"
  end

  def update_setup
    # @corporative = Corporative.new(JSON(params[:corporative].to_json))
    @corporative = Corporative.new(params[:corporative])
    if @corporative.save
      render :action => "update_setup"
    else
      render :action => (params[:form_action] || 'setup')
    end
  end

  # Página de redes sociales
  def snetworking
    @page_title = t('snetworks.title')
    @departments=Department.order('position').select{|a| a.sorganizations.present?}
    @breadcrumbs_info = [[@page_title, snetworking_site_path]]
    respond_to do |format|
      format.html
    end
  end

  # Páginas englobadas en "sobre irekia"
  def page
    if !(Page.about_pages + Page.predefined_pages).collect {|a| a[:label]}.include?(params[:label])
      raise ActiveRecord::RecordNotFound and return
    end

    @page = Page.send(params[:label])
    @breadcrumbs_info = [[(Page.about_pages+Page.predefined_pages).detect {|a| a[:label] == params[:label]}[:title], page_site_path(:label => params[:label])]]

    respond_to do |format|
      format.html {
        render :template => "/pages/show"
      }
      format.floki {
        render :template => "/pages/show.floki"
      }
    end

  end

  # Listado de todos los Feeds RSS
  def feeds
    @departments = Department.active.order("position")
    @title = t('documents.feeds_rss')
    @breadcrumbs_info = [[@title, feeds_site_path]]
    @feed_types = ['news', 'comments']
    @feed_types << 'proposals' if Settings.optional_modules.proposals
    @feed_types << 'debates' if Settings.optional_modules.debates
    respond_to do |format|
      format.html
    end
  end

  def email_item
    if !params[:t].blank? && %(News Event Page Proposal Album Photo Video).include?(params[:t])
      @document = params[:t].constantize.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  # Envia la noticia a un amigo
  def send_email
    if %(News Event Page Proposal Album Photo Video).include?(params[:t])
      @document = params[:t].constantize.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end

    if params[:sender_name].blank? || params[:recipient_name].blank? || params[:recipient_email].blank?
      flash[:error] = t('share.todos_campos')
      render :action => "email_item" and return
    elsif !params[:recipient_email].match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
      flash[:error] = t('share.email_incorrecto')
      render :action => "email_item" and return
    end

    begin
      logger.info("Mandando documento")
      Notifier.email_document(params[:sender_name], params[:recipient_name], params[:recipient_email], @document).deliver
      flash[:notice] =  t('share.pagina_enviada')
    rescue Net::SMTPServerBusy, Net::SMTPSyntaxError => err_type
      logger.info("Error al mandar mail de pagina: " + err_type)
      flash[:error] = t('session.Error_servidor_correo')
    end

    redirect_to @document
  end

  def user_default
    redirect_to default_url_for_user
  end

  def sitemap
    respond_to do |format|
      format.xml
    end
  end

  private
  def get_iphone_info
    @news = News.published.listable.translated.include(:organization)
        .order("featured, published_at DESC").limit(11)
    @fn = @news.delete_at(0)

    @events = Event.published.translated.future(Time.zone.now - 1.day).limit(10)
  end

  def should_translate_url_slug(referer_params)
    !referer_params[:id].blank? && referer_params[:action].eql?("show") &&
    %w(documents news events pages pages videos proposals).include?(referer_params[:controller])
  end

  def setup_admin_required
    admin_required if User.count > 0
  end

end
