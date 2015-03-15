# Modificar datos de usuario para usuarios con privilegios
# (todos menos Person, Journalist y Politician sin permisos)
class Sadmin::AccountController < Sadmin::BaseController
  before_filter :access_to_sadmin_required

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  # Actualizar un usuario
  def update
    if params[:submit_cancel]
      redirect_to admin_users_path
    else
      @user = current_user
      if params[:user][:type]
        # Tengo que hacer esto para que cambie el class de user y actualice bien el departamento
        @user.type= params[:user][:type]
        @user.save
        @user = User.find(params[:id])
      end

      if @user.update_attributes(user_params)
        flash[:notice] = 'El usuario se ha actualizado correctamente.'
        redirect_to sadmin_account_url
      else
        render :action => 'edit'
      end
    end
  end

  private
  def access_to_sadmin_required
    if !logged_in? || current_user.is_a?(Person) || current_user.is_a?(Journalist) || (current_user.is_a?(Politician) && current_user.permissions.empty?)
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  def user_params
    if @user.is_a?(Politician)
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :telephone, :url, 
        :photo, :public_role_es, :public_role_eu, :public_role_en, :gc_id, :description_es, :description_eu, 
        :description_en, :department_id, :attachments_attributes => [:show_in_es, :show_in_eu, :show_in_en, :file])
    else
      params.require(:user).permit(:email, :password, :password_confirmation, :name, :last_names, :telephone, :url, 
        :photo, :public_role_es, :public_role_eu, :public_role_en, :gc_id, :description_es, :description_eu, 
        :description_en, :department_id)      
    end
  end

end
