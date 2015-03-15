# Controlador para los procesos de login/logout.
# include ActionView::Helpers::UrlHelper
# Rails.application.routes.url_helpers.path_that_i_was_referencing_in_a_model

class SessionsController < ApplicationController
  skip_before_filter :well_be_back_soon, :only => [:new, :create, :destroy]
  skip_before_action :verify_authenticity_token, only: [:destroy], if: -> {request.format.to_s.eql?('floki')}

  # Formulario de inicio de sessión
  def new
    @title = t('session.login_in', :name => Settings.site_name)
    @breadcrumbs_info = [[@title, login_path]]
    if request.xhr?
      render :template => 'sessions/new_for_nav', :layout => false and return
    end
  end

  # Creación de una sessión, es decir, login.
  def create
    self.current_user = User.authenticate(params[:email], params[:password])
    process_login
  end

  # Logout del sistema
  def destroy
    # store_previous_location unless session[:return_to]
    if logged_in?
      @user_name = current_user.name
      SessionLog.create(:user_id => current_user.id, :action => "logout", :action_at => Time.zone.now, :user_ip => request.remote_ip)
      self.current_user.forget_me
    end
    cookies.delete :auth_token
    reset_session
    session[:return_to]=request.referer if request.referer && !request.referer.match(/account/)
    respond_to do |format|
      format.html do
        flash[:notice] = t('session.Has_salido', :name => @user_name)
        redirect_back_or_default(root_path)
      end
      format.floki do
        render :json => ''
      end
    end
  end

  # Envio de la contraseña por correo electrónico
  # Las nuevas cuentas quedan pendientes de activación por el usuario.
  # Esta acción activa la cuenta a partir del email que se le mandó al usuario al registrarse.
  def email_activation
    @user = User.find_by_email_and_status(params[:email], "pendiente")

    if @user
      begin
        logger.info("Mandando activacion a #{@user.email}")
        Notifier.activate_person_account(@user).deliver
      rescue Net::SMTPServerBusy, Net::SMTPSyntaxError => err_type
        logger.info("Error al mandar mail de activacion: " + err_type)
        flash[:error] = t('session.Error_servidor_correo')
      else
        flash[:notice] = t('session.activacion_enviada')
      end
    else
      flash[:error] = t('session.No_hay_usuario')
    end

    return_to = params[:return_to].eql?(embed_login_path) ? embed_login_path : login_path
    redirect_to return_to and return
  end

  # def mobile
  #   render :action => 'mobile.html', :layout => false
  # end

  def auth_info
    render :action => 'auth_info.json', :layout => false
  end

  def nav_user_info
    render :partial => '/shared/nav_user_logged', :layout => false
  end

  private

  def process_login
    if logged_in?      
      SessionLog.create(:user_id => current_user.id, :action => "login", :action_at => Time.zone.now, :user_ip => request.remote_ip)

      respond_to do |format|
        format.html do
          if params[:remember_me] == "1"
            self.current_user.remember_me
            cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          end
          # flash[:notice] = t('session.Has_entrado', :name => current_user.name) if !request.xhr?
          if params[:home].present? || request.xhr?
            render :json => true, :status => :ok
          else
            redirect_back_or_default(default_url_for_user)
          end
        end
        format.floki do
          if params[:remember_me] == "1"
            self.current_user.remember_me
            remember_time = 20.year
          else
            remember_time = 2.hour
          end
          self.current_user.remember_me_for(remember_time)
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => (Time.zone.now + remember_time)}
          flash[:error] = nil
          render :template => 'sessions/success.floki', :layout => false
        end
      end
    else
      if @user = User.find_by_email_and_status(params[:email], "pendiente")
        respond_to do |format|
          format.html {
            if request.xhr?
              render :json => t('session.No_has_activado_cuenta', :link => view_context.link_to(t('pincha_aqui'), email_activation_session_path(:email => params[:email])).html_safe).to_json, :status => 500
            else
              render :template => "/sessions/waiting_for_approval"
            end
          }
          format.floki {
            render :action => 'waiting_for_approval.floki', :layout => "application.floki.erb"
          }
        end
      else
        respond_to do |format|
          format.html do
            if request.xhr?
              render :json => [['email'], ['password']].to_json, :status => 500
            else
              flash[:error] = t('session.Email_incorrecto')
              render :action => 'new'
            end
          end
          format.floki do
            flash[:error] = t('session.Email_incorrecto')
            render :action => 'new.floki', :layout => false
          end
        end
      end
    end
  end

end
