# Controlador para la administración de permisos.
class Admin::PermissionsController < Admin::BaseController
  before_filter :get_user
  before_filter :super_user_required
  
  # Actualizar los permisos
  def update
    if @user.update_permissions(params[:perm])
      flash[:notice] = "Los permisos se han guardado correctamente"
      redirect_to admin_user_path(@user)
    else
      render :action => "edit"
    end
  end
  
  private
  # Filtro para coger el usuario. Los permisos siempre van asociados a un usuario.
  def get_user
    @user = User.find(params[:user_id])
  end

  def set_current_tab
    @current_tab = :users
  end
  
end
