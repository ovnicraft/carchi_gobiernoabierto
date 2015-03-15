# Controlador para el registro de periodistas 
class JournalistsController < ApplicationController

  # Formulario de registro
  def new
    @user = Journalist.new
    @title = t('users.registro_periodistas')
    @breadcrumbs_info = [[@title, new_journalist_path]]
    respond_to do |format|
      format.html
    end
  end
  
  # Creación de cuenta de periodista.
  def create
    @user = Journalist.new(journalist_params)
    @user.user_ip = request.remote_ip
    
    if @user.save
      cookies.delete :auth_token
      # protects against session fixation attacks, wreaks havoc with
      # request forgery protection.
      # uncomment at your own risk
      # reset_session
      # self.current_user = @user
      @title = t('users.Gracias_por_alta')
    else
      @title = t('users.registro_periodistas')
      render :action => "new"
    end
  end

  def journalist_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :photo, 
      :remove_photo, :subscription, :bulletin_email, :wants_bulletin, :alerts_locale, :normas_de_uso, 
      :telephone, :media, :url, :departments, :subscriptions_attributes => [:department_id])
  end

end
