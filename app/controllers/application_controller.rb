# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
# require 'acts_as_taggable_on_steroids_will_paginate'
require 'authenticated_system'
require 'form_submit_tag_helper'
require 'csv'
require 'in_place_with_auto_complete'
require 'couchrest'
require 'open-uri'
# require 'cache_extension_fix'
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include AuthenticatedSystem

  include GeoKit::Geocoders

  include Tools::BulletinClickEncoder

  def default_url_options(options={})
    { locale: I18n.locale }
  end

  # Idiomas disponibles a lo largo del site
  def locales
    AvailableLocales::AVAILABLE_LANGUAGES
  end
  helper_method :locales

  before_filter :http_authentication
  # before_filter :well_be_back_soon

  before_filter :set_locale
  before_filter :set_current_user
  before_filter :adjust_format_for_iphone
  before_filter :get_areas


  def am_I?(user)
    logged_in? && current_user && user && current_user.id == user.id #  && (private_profile? || politician_profile?)
  end

  private

  # Determina el idioma preferido del visitante de la web. Se determina, por este orden:
  # * Idioma especificado en la URL
  # * Idioma guardado en la cookie, elegido en la pantalla "splash" de elección de idioma
  # * Idioma por defecto de la aplicación: castellano
  #
  # Se llama antes de cada petición a la web con un <tt>before_filter</tt>
  def set_locale
    @locale = params[:locale] || cookies['locale'] || I18n.default_locale.to_s
    unless AvailableLocales::AVAILABLE_LANGUAGES.keys.include?(@locale.to_sym)
      @locale = I18n.default_locale
    end
    cookies['locale'] = { :value => @locale , :expires => 1.year.from_now } if @locale != cookies['locale']
    I18n.locale = @locale.to_sym
  end

  # Da valor al usuario actual, para poder rellenar los campos <tt>updated_by</tt> y <tt>created_by</tt>
  # de todos los modelos observados por #UserActionObserver.
  #
  # Se llama desde <tt>before_filter</tt>
  def set_current_user
    UserActionObserver.current_user = current_user.id if current_user.is_a?(User)
    cookies[:openirekia_uuid] = {:value => UUIDTools::UUID.timestamp_create.to_s, :expires => 20.years.from_now } unless cookies[:openirekia_uuid].present?
  end

  # Requiere autentificación por HTTP para toda la web. Está actualmente desactivado.
  # Se llama desde <tt>before_filter</tt>
  def http_authentication
    # el WebView no tiene floki user agent
    if Rails.application.secrets['http_auth'] && Rails.env != 'test' && !floki_user_agent? && !request.env["HTTP_USER_AGENT"].to_s.match(/iPhone/i)
      authenticate_or_request_with_http_basic do |username, password|
        username == Rails.application.secrets['http_auth']['user_name'] && password == Rails.application.secrets['http_auth']['password']
      end
    else
      return true
    end
  end

  def well_be_back_soon
    if logged_in? && current_user.is_staff?
      return true
    else
      render :template => "/site/well_be_back_soon.html", :layout => false
    end
  end

  # Determina el formato a devolver si la petición se hace desde un iphone
  def adjust_format_for_iphone
    if floki_user_agent?
      request.format = :floki unless params[:format]
    end
  end
  
  def store_session_return_to
    session[:return_to] = params[:return_to] || request.env['HTTP_REFERER'] || root_path
  end

  def floki_user_agent?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(Irekia|floki)/i]
  end
  helper_method :floki_user_agent?

  def ipad_app_request?
    if cookies["DINFO"].present?
      width = cookies["DINFO"].split(/,/)[0].to_i
      floki_user_agent? && (width > 640)
    else
      floki_user_agent? && params[:d].present? && params[:d].to_i == 1
    end
  end
  helper_method :ipad_app_request?

  def iphone4_app_request?
    if cookies["DINFO"].present?
      dpi = cookies["DINFO"].split(/,/)[2].to_i
      floki_user_agent? && (dpi == 326)
    else
      floki_user_agent? && params[:d].present? && params[:d].to_i == 2
    end
  end
  helper_method :iphone4_app_request?

  def retina_display_request?
    if cookies["DINFO"].present?
      dpi = cookies["DINFO"].split(/,/)[2].to_i
      floki_user_agent? && (dpi > 200)
    end
  end
  helper_method :retina_display_request?

  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record
  rescue_from WillPaginate::InvalidPage, :with => :bad_record
  rescue_from ActionController::UnknownFormat, :with => :bad_record
  # Devuelve la página de "página no encontrada" cuando no se encuentra alguna petición en
  # la base de datos. Se llama desde <tt>rescue_from</tt>
  def bad_record
    if [:floki, :html].include?(request.format.to_sym)
      render :template => '/site/notfound.html', :layout => 'application', :status => 404
    else
      render :template => '/site/notfound.html', :layout => false, :status => 404
    end
  end

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalid_token
  # Cuando un usuario hace logout en una pestaña y luego intenta rellenar un formulario en otra pestaña
  # le da error InvalidAuthenticityToken. Mejor decirle que su sesión ha caducado
  def invalid_token
    flash[:notice] = t('session.sesion_caducada')
    redirect_to new_session_path(:locale => I18n.locale, :return_to => request.env["HTTP_REFERER"])
  end

  # HQ
  rescue_from ActiveRecord::SubclassNotFound, :with => :questions_disabled
  def questions_disabled
    unless exception.match(/The single-table inheritance mechanism failed to locate the subclass: 'Question'/)
      raise ActiveRecord::SubclassNotFound
    end
  end

  rescue_from ActionController::RedirectBackError, :with => :redirect_to_root
  def redirect_to_root
    redirect_to root_path
  end

  # Respuesta "Service unavailable"
  # Se usa para los controllers que heredan de Embed::BaseController
  # El resultado de los requests a acciones de estos controllers se mustra en un iframe.
  # Si hay un error no queremos que salga en el iframe por esto el body está vacío.
  # También se usa para el notfound the URL que contienen "embed".
  def service_unavailable
    render :nothing => true, :status => 503
  end

  # Devuelve la lista de tags para un <tt>autocomplete</tt> de tags.
  def auto_complete_for_tag_list(search_string, beginning_of_string=true)
    exclusion_list = []
    @tags = []

    # "_" parece ser un simbolo reservado en los LIKE clauses, así que si buscamos tags ocultos, hay que escaparlo
    raw_param = search_string.tildes
    parsed_param = raw_param.match(/^_/) ? raw_param.sub(/^_/, '\\_'): raw_param

    find_pattern = parsed_param + '%'
    find_pattern = '%' + find_pattern unless beginning_of_string

    # Los tags hay que introducirlos en castellano y luego se traducen a otros idiomas
    conditions = ["tildes(name_es) ILIKE :tag_list", {:tag_list => find_pattern}]
    if exclusion_list.length>0
      conditions[0] << " AND id NOT IN (#{exclusion_list.join(', ')})"
    end

    # ActsAsTaggableOn::Tag.where(conditions).each do |t|
    #   t[:nombre] = t.name_es
    #   exclusion_list << t.id
    #   @tags << t
    # end
    @tags = ActsAsTaggableOn::Tag.where(conditions)
    exclusion_list = @tags.map(&:id)
    
    return @tags
  end

  # Devuelve la lista de tags para un <tt>autocomplete</tt> de tags.
  # Primero salen los tags que empiezan por el texto introducido 
  # y luego los tags que tienen este texto dentro del nombre del tag.  
  def auto_complete_for_tag_list_first_beginning_then_the_rest(search_string)
    auto_complete_for_tag_list(search_string)
    tags_beginning = @tags
    auto_complete_for_tag_list(search_string, false)
    @tags = (tags_beginning + @tags).uniq
    
    return @tags
  end

  # URL por defecto para cada usuario: corresponde a
  # - el enlace "Tú irekia" en la home para políticos, ciudadanos y periodistas,
  # - el enlace "Administración" para los usuarios que tienen acceso a la admin,
  # - el redirect después de login
  # - el link con el nombre del usuario en la barra de navegación (2DO)
  def default_url_for_user
    if logged_in?
      if current_user.is_admin?
        admin_path
      elsif current_user.is_a?(DepartmentMember) || current_user.is_a?(DepartmentEditor) || current_user.is_a?(StaffChief) || current_user.is_a?(StreamingOperator) || current_user.is_a?(Colaborator)
        admin_path
      elsif current_user.is_a?(StreamingOperator)
        admin_stream_flows_path
      elsif current_user.is_a?(RoomManager)
        sadmin_account_path
      elsif current_user.is_a?(Politician)
        if current_user.has_admin_access?
          admin_path
        else
          politician_path(current_user)
        end
      else
        account_path
      end
    else
      root_path
    end
  end
  helper_method :default_url_for_user

  # Determina si el usuario actual tiene permiso para ver la administración de los
  # contenidos de tipo <tt>doc_type</tt>.
  # <tt>doc_type</tt> puede tener los valores: news, events, videos, photos, pages, links, stream_flows

  def can_access?(doc_type)
    logged_in? && (current_user.can_access?(doc_type) || can?('access', doc_type))
  end
  helper_method :can_access?

  # Determina si el usuario actual tiene permiso para modificar los
  # contenidos de tipo <tt>doc_type</tt>.
  def can_edit?(doc_type)
    logged_in? && (current_user.can_edit?(doc_type) || can?('edit', doc_type))
  end
  helper_method :can_edit?

  # Determina si el usuario actual tiene permiso para crear los
  # contenidos de tipo <tt>doc_type</tt>.
  def can_create?(doc_type)
    logged_in? && (current_user.can_create?(doc_type) || can?('create', doc_type))
  end
  helper_method :can_create?

  # Determina si el usuario actual tiene permiso de tipo <tt>perm_type</tt> en los
  # contenidos de tipo <tt>doc_type</tt>. Ver Permission#can?
  def can?(perm_type, doc_type)
    logged_in? && current_user.can?(perm_type, doc_type)
  end
  helper_method :can?

  # Determina si el usuario actual tiene permiso para modificar el evento <tt>event</tt>.
  def can_edit_event?(event)
    if current_user.is_a?(DepartmentMember) || current_user.is_a?(Politician)
      event.visible_in.collect {|subsite| current_user.can?("create_#{subsite}", "events")}.uniq != [false]
    else
      can_edit?("events")
    end
  end
  helper_method :can_edit_event?

  # Determina si el usuario puede ver las estadísticas de consultas y descragas de una noticia o un evento.
  def can_see_stats?
    logged_in? && (is_admin? || current_user.is_a?(DepartmentEditor))
  end
  helper_method :can_see_stats?

  # Filtro que determina si el usuario puede entrar en la administración de comentarios
  def access_to_comments_required
    unless (logged_in? && (can_edit?("comments") || can?("official", "comments")))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # # Devuelve la ruta a la versión de tamaño <tt>size</tt> de la imagen <tt>path</tt>
  # def photo_size_path(path, size="original")
  #   path = Pathname.new(path)
  #   return "#{path.dirname}/#{size}/#{path.basename}"
  # end
  # helper_method :photo_size_path


  def taggable_modules
    [News, Event, Page, Video, Photo, Proposal, Headline]
  end
  helper_method :taggable_modules

  def document_subclasses
    [News, Event, Page]
  end
  helper_method :document_subclasses

  # Irekia3
  def get_areas
    @areas = Area.ordered
  end

  def get_followings
    item = @politician.present? ? @politician : @area
    if logged_in? && current_user.follows?(item)
      @following = Following.where(:followed_id => item.id, :user_id => current_user.id, :followed_type => item.class.name).first
    else
      @following = Following.new
    end
    @following
  end
  helper_method :get_followings

  def get_selected_date
    @selected_date = {}
    @today = Time.zone.now
    [:year, :month].each do |key|
      @selected_date[key] = (params[key].to_i > 0) ? params[key].to_i : @today.send(key.to_s)
    end
    # Si no está indicada la fecha, cogemos el día 1, para evitar problemas con los enlaces
    # mes siguiente - mes anterior.
    # Como efecto secundario, si llamamos a la acción list sin argumentos nos devolverá
    # la lista de eventos del día 1 del mes actual.
    @selected_date[:day] = (params[:day].to_i > 0) ? params[:day].to_i : 1

    @year = @selected_date[:year]
    @month = @selected_date[:month]
    @day = @selected_date[:day]

    @date = Date.valid_date?(@year, @month, @day) ? Date.new(@year, @month, @day) : Date.today
  end

  def get_area
    @area = Area.find(params[:area_id]) if params[:area_id]
  end

  def get_politician
    @politician = Politician.find(params[:politician_id]) if params[:politician_id]
  end


  # Las acciones pueden pertenecer a un área, un político, un ciudadano
  # o podemos coger las últimas acciones en general (para la home)
  def get_context
    if params[:area_id] && Area.exists?(params[:area_id].to_i)
      @context = Area.find(params[:area_id])
      @area = @context
      @breadcrumbs_info = [[t('organizations.title'), areas_path]]
      @breadcrumbs_info << [@area.name,  area_path(@area)]
    elsif params[:politician_id] && params[:politician_id].to_i != 0 && Politician.exists?(params[:politician_id].to_i)
      @context = Politician.find(params[:politician_id])
      @politician = @context
      @breadcrumbs_info = [[t('politicians.title'), politicians_path]]
      @breadcrumbs_info << [@politician.public_name,  politician_path(@politician)]
    elsif params[:user_id] && User.exists?(params[:user_id])
      @context = User.find(params[:user_id])
      @user = @context
      @breadcrumbs_info = [[@user.public_name, user_path(@user)]]
    end
  end

  def context_type
    case @context.class.name.to_s.downcase
    when 'politician'
      @context.class.name.to_s.downcase
    when 'person'
      'user'
    when 'area'
      @context.class.name.to_s.downcase
    else
      'user'
    end
  end

  # Devuelve la lista de acciones dentro de un context: area, político o todas (ciudadano?)
  def get_context_actions(context=nil)
    if context.present?
      news_finder = context.news.listable
      events_finder = context.events
      proposals_finder = context.approved_and_published_proposals
      comments_finder = context.approved_comments
      arguments_finder = context.approved_arguments
    else
      news_finder = News.published.translated.listable
      events_finder = Event.published.translated
      proposals_finder = Proposal.approved.published
      comments_finder = Comment.approved
      arguments_finder = Argument.published.for_proposals
    end

    actions = []
    actions << news_finder
      .select("documents.id, title_es, title_eu, title_en, body_#{I18n.locale}, published_at, has_comments,
                  comments_closed, multimedia_path, cover_photo_file_name")
      .reorder("published_at DESC").limit(20) if news_finder

    actions << events_finder
        .select("documents.id, title_es, title_eu, title_en, body_#{I18n.locale}, published_at, starts_at, ends_at, has_comments, comments_closed")
        .reorder("published_at DESC").limit(20) if events_finder

    actions << proposals_finder
      .select("proposals.id, title_es, title_eu, title_en, body_#{I18n.locale}, published_at, status, user_id, has_comments, comments_closed")
      .reorder("published_at DESC").limit(20)

    actions << comments_finder
      .select("comments.id, commentable_id, commentable_type, user_id, body, created_at, status, name, email")
      .reorder("created_at DESC").limit(20) if comments_finder

    actions << arguments_finder
      .select("argumentable_type, argumentable_id, value, reason, published_at, user_id")
      .reorder("created_at DESC").limit(20) if arguments_finder

    actions = actions.flatten.sort {|a,b| b.published_at <=> a.published_at}[0..19].map {|a| a.is_a?(Event) ? a.reload : a}

    actions
  end

  def prepare_news(context, is_xhr)
    # No quieren que se vean las noticias ocultas (acuerdos de consejo y tres compromisos)
    # Las noticias ocultas no se ven en el home de Irekia ni en /news pero sí a través de link de
    # la crónica de acuerdos de consejo, siguiendo un tag o la búsqueda o en las noticias de cada área

    if context
      @news = @context.news.paginate(:page => params[:page], :per_page => 15).reorder('published_at DESC')
      @title = "#{t('news.title')} #{t('shared.from_context', :name => context.public_name)}"
      if is_xhr
      else
        @leading_news = @context.featured_news.reorder("documents.published_at DESC").first
        if @leading_news
          @other_news = @news - [@leading_news]
        else
          @leading_news, @other_news = @news[0], @news[1..-1]
        end
      end
    else
      @title = t('news.leading_news')
      @news = News.published.translated.listable.paginate(:page => params[:page], :per_page => 15).reorder('published_at DESC')
      if is_xhr
      else
        get_month_events
        @headlines = Headline.published.translated.recent.limit(12) if Settings.optional_modules.headlines
        @streaming = Streaming.new
        if params[:page].present?
          @other_news = @news
        else
          @leading_news = News.featured_a
          @secondary_news = News.featured_4b
          @other_news = (@news - [@leading_news] - @secondary_news)[0..15]
        end
      end
    end
  end

  def get_news_videos_and_photos(news)
    videos = news.videos
    videos_list = videos[:list][I18n.locale.to_sym].present? ? videos[:list][I18n.locale.to_sym].sort : []
    @videos = ([news.featured_video] + videos_list).compact

    @videos_mpg = news.videos_mpg #videos[:mpg][I18n.locale.to_sym]

    # Mostramos todas las fotos del directorio multimedia de la noticia
    @photos = news.photos
    if news.cover_photo?
      @photos.to_a.delete_if {|ph| File.basename(ph).eql?(news.cover_photo_file_name)}
      @photos.insert(0, news.cover_photo)
    end
  end

  def get_month_events
    get_selected_date if @day.nil? && @month.nil? && @year.nil?
    @events = Event.published.translated.where("ends_at > ?", Time.zone.now.beginning_of_day).reorder("starts_at").limit(15)
    if @context
      @month_events = @context.events.month_events_by_day4cal(@month, @year)
    else
      @month_events = Event.published.translated.month_events_by_day4cal(@month, @year)
    end
  end

  # Construye los <tt>breadcrumbs</tt> o "migas de pan" que indican la ruta para llegar hasta
  # cada página de la web.
  #
  # Se llama antes del <tt>render</tt> de cada página
  def make_breadcrumbs
    @breadcrumbs_info = [] unless @breadcrumbs_info
  end

  # Queremos saber en qué noticias relacionadas pinchan los usuarios
  def track_clickthrough
    # logger.info "trackkkkkkkkkkkkkkkkkk #{request.request_uri}: #{request.env['HTTP_REFERER']}"
    if params[:track] && params[:track].to_i == 1 && request.env['HTTP_REFERER']
      begin
        referer = request.env['HTTP_REFERER'].gsub(/^#{request.protocol}#{request.host_with_port}/, '')
        dummy, referer_path, dummy2, referer_querystring = get_params_for(referer)
        # referer_params = ActionDispatch::Routing::Routes.recognize_path(referer_path, :method => :get)
        referer_params = Rails.application.routes.recognize_path(referer_path, :method => :get)

        dummy, current_page_path, dummy2, current_page_querystring = get_params_for(request.url)
        current_page_params = Rails.application.routes.recognize_path(current_page_path, :method => :get)

        if referer_params[:controller].eql?('search')
          click_source_type = 'Criterio'
        elsif referer_params[:controller].eql?('tags')
          click_source_type = 'ActsAsTaggableOn::Tag'          
        else
          click_source_type = referer_params[:controller].classify.constantize.base_class.to_s
        end

        click_source_id = case click_source_type
          when 'Order'
            Order.find_by_no_orden(referer_params[:no_orden] ).id
          when 'ActsAsTaggableOn::Tag'
            ActsAsTaggableOn::Tag.find_by_sql(["SELECT * FROM tags WHERE (sanitized_name_es=? OR sanitized_name_eu=? OR sanitized_name_en=?)", referer_params[:id], referer_params[:id], referer_params[:id]]).first.id
          else
            referer_params[:id]
          end

        click_target_type = current_page_params[:controller].classify.constantize.base_class.to_s

        click_target_id = case click_target_type
          when 'Order'
            Order.find_by_no_orden(current_page_params[:no_orden]).id
          else
            current_page_params[:id]
          end

        Clickthrough.create :click_source_type => click_source_type, :click_source_id => click_source_id,
          :click_target_type => click_target_type, :click_target_id => click_target_id,
          :locale => I18n.locale.to_s, :user_id => (logged_in? ? current_user.id : nil),
          :uuid => cookies[:openirekia_uuid]
      rescue => err
        logger.error "No he podido guardar el clickthrough de #{referer} a #{request.url}: #{err.inspect}"
      end
    end
  end

  def resource_for(controller)
    document.is_a?(News) ? "documents" : document.class.to_s.downcase.pluralize
  end

  def get_params_for(url)
    dummy, path, dummy2, querystring = url.match(/([^\?]+)(\?(.+))*/).to_a
  end

  # get criterio to highlight matching keywords in news, order, etc.
  # used in news, order controllers before show action
  def get_criterio
    @criterio = Criterio.find(params[:criterio_id].to_i) if params[:criterio_id].present?
  end

  def do_elasticsearch_and_save_results(save_criterio = true, only_title = false)
    # Results
    all_results=Elasticsearch::Base::do_elasticsearch_with_facets(@criterio, @from, @sort, only_title, I18n.locale)
    return false if all_results.empty?  # elasticsearch not available

    @search_results=all_results['hits']
    @total_hits=all_results['total_hits']

    # Facets
    @search_facets=Hash.new
    Elasticsearch::Base::FACETS.keys.each do |facet_type|
      exp = @criterio.title.match("(#{facet_type}: (.*))( AND|$)")
      if exp.present? && exp[2].present?
        @search_facets[facet_type] = all_results['facets'][facet_type].to_a.delete_if{|a,b| "#{facet_type}: #{exp[2]}".match(Regexp.escape(a))}
      else
        @search_facets[facet_type] = all_results['facets'][facet_type]
      end
    end

    # Suggestions
    @suggestion = all_results['suggestion']

    update_criterio if save_criterio
    return true
  end

  def update_criterio
    @criterio.results_count=@total_hits
    if @suggestion.present? && @total_hits > 0
      # store fixed misspelling
      all = @criterio.title.match(/.*keyword\: (.*)\z/)
      if all.present? && all[1].present?
        @criterio.misspell = @criterio.misspell.to_s + all[1]
        @criterio.title = @criterio.title.gsub(/[ AND ]?keyword: #{all[1]}\z/, " keyword: #{@suggestion}").strip
      end
    end
    if @criterio.save
      session[:criterio_id]=@criterio.id
      @criterio.reload
    else
      @criterio.destroy
    end
    @criterios=@criterio.ancestors.reverse + [@criterio]
  end

  def elasticsearch_not_available_redirect_url
    flash[:error]=t('search.servidor_no_disponible')
    if request.referer.present?
      request.referer
    elsif !(params[:controller].eql?('search') && params[:action].eql?('new'))
      new_search_path
    else
      root_path
    end
  end

  def set_sort_order
    if params[:sort].present? && params[:sort].eql?('date')
      @sort='date'
    end
  end

  def set_page
    if params[:page]
      @page=params[:page]
      @from=(params[:page].to_i-1)*Elasticsearch::Base::ITEMS_PER_PAGE
    else
      @page=1
      @from=0
    end
  end          

  def category_name_and_url(category)
    if match = category.name.match(/\"(.+)\":(.+$)/)
      if match[2].match("http://")
       [match[1], match[2], {:rel => 'external'}]
      else
        [match[1], match[2], {}]
      end
    else
      if category.name.match(/\+$/)
        [category.pretty_name, '#', {}]
      else
        [category.pretty_name, category_path(category), {}]
      end
    end
  end
  helper_method :category_name_and_url

  def get_full_width_param
    if params[:fwidth].eql?('1')
      @full_width = true
    end
  end

  def string_to_time(val)
    val.is_a?(String) ? Time.zone.parse(val) : val
  end
  helper_method :string_to_time

  # Filtro que comprueba que el usuario está logeado y está aprobado.
  # Se usa en los controllers de sadmin y admin para evitar el acceso de usuarios vetados
  # que no han cerrado la sesión
  def approved_user_required
    unless (logged_in? && current_user.approved?)
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  protected
    # Inspired by:
    # http://www.aldenta.com/2006/09/25/execute-rails-code-before-the-view-is-rendered/
    # Redefinición del método render para que se construyan antes los <tt>breadcrumbs</tt>
    def render(options = nil, extra_options = {}, &block)
      # we want to build the breadcrums just before rendering
      make_breadcrumbs

      # call the ActionController::Base render to show the page
      super
    end

end
