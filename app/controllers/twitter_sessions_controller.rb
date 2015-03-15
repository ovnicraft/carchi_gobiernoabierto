class TwitterSessionsController < ApplicationController
  skip_before_filter :http_authentication

  def create
    request_token = oauth.authentication_request_token(:oauth_callback => finalize_twitter_session_url)
    session['rtoken']  = request_token.token
    session['rsecret'] = request_token.secret

    session[:return_to] = params[:return_to] || request.env['HTTP_REFERER'] || root_path
    if Rails.env.eql?("test")
      redirect_to finalize_twitter_session_url(oauth_verifier: "test")
    else
      redirect_to request_token.authorize_url
    end

  end

  def finalize
    if params[:oauth_verifier]
      access_token = oauth.authorize(session['rtoken'], session['rsecret'], :oauth_verifier => params[:oauth_verifier])

      session['rtoken']  = nil
      session['rsecret'] = nil

      profile = oauth.info

      if profile.has_key?("errors")
        logger.info "Error al hacer login con Twitter: #{profile.inspect}"
        flash[:error] = "Ha sido imposible completar el login. Por favor, inténtelo más tarde"
        redirect_back_or_default(root_path) and return
      end

      profile_attrs = {:atoken => access_token.token,
        :asecret => access_token.secret,
        :name => profile['name'],
        :screen_name => profile['screen_name'],
        :raw_location => profile['location'],
        :url => "http://www.twitter.com/#{profile['screen_name']}"}

      user = Person.find_or_initialize_by(screen_name: profile['screen_name'])

      if user.new_record?
        user.update_attributes(profile_attrs.merge({:status => "aprobado"}))
        self.current_user = user
        # flash[:notice] = t('session.Has_entrado', :name => current_user.name)
        redirect_back_or_default(root_path) and return
      else
        user.update_attributes(profile_attrs)
        if user.status.eql?("pendiente")
          render :template => "/sessions/waiting_for_approval" and return
        elsif user.status.eql?("vetado") || user.status.eql?("eliminado")
          flash[:notice] = "Este usuario ha sido eliminado"
          redirect_back_or_default(root_path) and return
        else
          self.current_user = user
          flash[:notice] = t('session.Has_entrado', :name => current_user.name)
          redirect_back_or_default(root_path) and return
        end
      end

    else
      flash[:error] = t('twitter_sessions.not_authorized')
      redirect_back_or_default(root_path) and return
    end
    session[:return_to] = nil
  end

  private
    def oauth
      consumer = Rails.application.secrets["twitter"]
      @oauth ||= TwitterOAuth::Client.new(:consumer_key => consumer['token'], :consumer_secret =>consumer['secret'])
    end

end
