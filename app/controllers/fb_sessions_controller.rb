#
# Login a través de Facebook
#
class FbSessionsController < ApplicationController
  skip_before_filter :http_authentication
  before_filter :get_facebook_settings

  attr_accessor :facebook_settings

  # Conectarse a https://www.facebook.com/dialog/oauth?client_id=YOUR_APP_ID&redirect_uri=YOUR_URL
  # Esto hace el login y luego redirect a http://YOUR_URL?code=A_CODE_GENERATED_BY_SERVER
  def create
    session[:return_to] = params[:return_to] || request.env['HTTP_REFERER']

    if Rails.env.eql?("test")
      redirect_to finalize_fb_session_path(:code => "fake")
    else
      redirect_to "https://graph.facebook.com/oauth/authorize?client_id=#{facebook_settings['application_id']}&redirect_uri=#{callback_url}"
    end
  end


  # Terminar el login:
  # aquí tenemos params[:code]. Llamamos la función get_user_profile para completar el login
  def finalize
    if not params[:code].nil?
      profile = get_user_profile

      if profile[:error].present?
        flash[:notice] = t('session.no_hemos_podido_confirmar_el_fb_login')
        redirect_back_or_default(root_path) and return
      else
        user = Person.find_or_initialize_by(fb_id: profile[:fb_id])
        if user.new_record?
          user.update_attributes(profile.merge({:status => "aprobado"}))
          self.current_user = user
          flash[:notice] = t('session.Has_entrado', :name => current_user.name)
          redirect_back_or_default(root_path) and return
        else
          if user.status.eql?("pendiente")
            render :template => "/sessions/waiting_for_approval" and return
          elsif user.status.eql?("vetado")
            flash[:notice] = "Este usuario ha sido eliminado"
            redirect_to root_path and return
          else
            self.current_user = user
            flash[:notice] = t('session.Has_entrado', :name => current_user.name)
            redirect_back_or_default(root_path) and return
          end
        end
      end

    else
      flash[:error] = t('fb_sessions.login_not_completed')
      redirect_back_or_default(root_path) and return
    end
    session[:return_to] = nil

  end

  private

  def get_facebook_settings
    @facebook_settings = Rails.application.secrets["facebook"]
  end

  def callback_url
    "http://" + ActionMailer::Base.default_url_options[:host] + finalize_fb_session_path
  end

  # Usando el code que hemos recibido llamamos a https://graph.facebook.com/oauth/access_token?
  #     client_id=YOUR_APP_ID&redirect_uri=YOUR_URL&
  #     client_secret=YOUR_APP_SECRET&code=THE_CODE_FROM_ABOVE
  # que nos devolverá el access token en el body del request
  # acess_token=xxxxxx&expires=nnn
  # Luego usamos el access token para obtener información sobre el usuario conectándonos a
  # https://graph.facebook.com/me?access_token=<el access_token>
  # esto nos da un json:
  # {
  #    "id": "1254107830",
  #    "name": "Eli Kroumova",
  #    "first_name": "Eli",
  #    "last_name": "Kroumova",
  #    "link": "http://www.facebook.com/profile.php?id=1254107830",
  #    "gender": "female",
  #    "timezone": 1,
  #    "locale": "es_ES",
  #    "verified": true
  # }
  def get_user_profile
    profile = {}

    url = URI.parse("https://graph.facebook.com/oauth/access_token?client_id=#{facebook_settings['application_id']}&redirect_uri=#{callback_url}&client_secret=#{facebook_settings['secret_key']}&code=#{CGI::escape(params[:code])}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    tmp_url = url.path+"?"+url.query

    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    data = response.body
    access_token = data.split("&").first.split("=")[1]
    # logger.info "FFFFFFFFFFFFFFFFFF response body: #{data}"
    # logger.info "FFFFFFFFFFFFFFFFFF access token: #{access_token}"
    unless access_token.present?
      profile[:error] = data
       # logger.info "FFFFFFFFFFFFFFFFFFFFFFFF error: #{profile[:error]}"
      return profile
    end

    url = URI.parse("https://graph.facebook.com/me?access_token=#{CGI::escape(access_token)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    tmp_url = url.path+"?"+url.query
    request = Net::HTTP::Get.new(tmp_url)
    response = http.request(request)
    user_data = response.body
    user_data_obj = JSON.parse(user_data)

    if user_data_obj["error"].present?
      profile[:error] = user_data_obj["error"]
    else
      profile[:fb_id] = user_data_obj["id"]
      profile[:atoken] = access_token
      profile[:asecret] = session['rsecret']
      profile[:name] = user_data_obj["first_name"]
      profile[:last_names] = user_data_obj["last_name"]
      profile[:url] = user_data_obj["link"]
    end

    profile
  end

end
