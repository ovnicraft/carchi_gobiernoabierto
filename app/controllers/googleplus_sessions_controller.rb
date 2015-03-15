require 'google/api_client'
class GoogleplusSessionsController < ApplicationController
  skip_before_filter :http_authentication

  def create
    session[:return_to] = params[:return_to] || request.env['HTTP_REFERER']

    authorization_uri = oauth.authorization_uri.dup
    authorization_uri.query_values = authorization_uri.query_values.merge({'approval_prompt' => 'auto'})

    if Rails.env.eql?("test")
      redirect_to finalize_googleplus_session_path(:code => "fake")
    else
      redirect_to authorization_uri.to_s
    end
  end

  def finalize
    if params[:code]
      oauth.code = params[:code]
      @oauth.fetch_access_token!

      @client.authorization = @oauth

      id_token = @client.authorization.id_token
      encoded_json_body = id_token.split('.')[1]
      # Base64 must be a multiple of 4 characters long, trailing with '='
      encoded_json_body += (['='] * (encoded_json_body.length % 4)).join('')
      json_body = Base64.decode64(encoded_json_body)
      body = JSON.parse(json_body)

      @token = {:refresh_token => @client.authorization.refresh_token,
        :access_token => @client.authorization.access_token,
        :expires_in => @client.authorization.expires_in,
        :issued_at => @client.authorization.issued_at}

      # now we should have access to user name
      userinfo_api = @client.discovered_api('oauth2', 'v2')

      response = @client.execute!(userinfo_api.userinfo.get)
      body2 = JSON.parse(response.body)

      if body2['id'].present?
        user = Person.find_or_initialize_by(googleplus_id:body2['id'])
        # , :email => body2['email'] => uniqueness of email. maybe the user is already registered with that
        profile_attrs = {:googleplus_id => body2['id'], :name => body2['given_name'], :last_names => body2['family_name']}

        if user.new_record?
          if user.update_attributes(profile_attrs.merge({:status => "aprobado"}))
            self.current_user = user
            session[:token] = @token
            redirect_back_or_default(root_path) and return
          else
            flash[:error] = I18n.t('session.error_googleplus')
            redirect_back_or_default(root_path) and return
          end
        else
          user.update_attributes(profile_attrs)
          if user.status.eql?("pendiente")
            render :template => "/sessions/waiting_for_approval" and return
          elsif user.status.eql?("vetado") || user.status.eql?("eliminado")
            flash[:notice] = "Este usuario ha sido eliminado"
            redirect_to root_path and return
          else
            self.current_user = user
            session[:token] = @token
            flash[:notice] = t('session.Has_entrado', :name => current_user.name)
            redirect_back_or_default(root_path) and return
          end
        end
      else
        flash[:error] = I18n.t('session.error_googleplus')
        redirect_back_or_default(root_path) and return
      end
    else
      flash[:error] = I18n.t('session.error_googleplus')
      redirect_back_or_default(root_path) and return
    end
    session[:return_to] = nil
  end

  private
    def oauth
      @consumer = Rails.application.secrets['googleplus']

      @client ||= Google::APIClient.new({:application_name => Settings.site_name,:application_version => "1.0"})
      @client.authorization.client_id = @consumer['client_id']
      @client.authorization.client_secret = @consumer['client_secret']
      @client.authorization.scope = 'openid profile'

      @oauth = @client.authorization.dup
      @oauth.grant_type = 'authorization_code'
      #redirect_uri = ActionMailer::Base.default_url_options[:host] + finalize_googleplus_session_path
      redirect_uri = request.url.match(/^http:\/\//).present? ? @consumer['redirect_uris'] : @consumer['redirect_uris'].gsub('http://', 'https://')
      @oauth.redirect_uri = redirect_uri
      @oauth
    end
end
