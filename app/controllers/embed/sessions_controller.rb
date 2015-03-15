class Embed::SessionsController < Embed::BaseController
  before_filter :set_title
  
  # Formulario de inicio de sessión para poder comentar en webs externas
  def new
    @irekia = true if params[:irekia].eql?('1')    
  end
  
  def create
    self.current_user = User.authenticate(params[:email], params[:password])
    process_login
  end
  
  def show
    if logged_in?
      flash.now[:notice] = t('session.Has_entrado', :name => current_user.name)
      render :action => "logged_in"
    else
      render :action => "new"
    end
  end
  
  def password_reset
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
          flash[:notice] = t('session.Has_entrado', :name => current_user.name)
          render :action => 'logged_in'
        end
      end
    else
      if @user = User.find_by_email_and_status(params[:email], "pendiente")
        respond_to do |format|
          format.html {
            @return_to = embed_login_path
            render :template => "/sessions/waiting_for_approval"
          }  
        end
      else
        respond_to do |format|
          format.html do
              flash[:error] = t('session.Email_incorrecto')
              render :action => 'new'  
          end
        end
      end
    end
  end

  def set_title
    @title = t('session.login_in', :name => Settings.site_name)    
  end  
  
end
