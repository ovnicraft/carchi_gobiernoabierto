# Controlador para la administración de Responsables de salas de streaming
class Admin::RoomManagersController < Admin::BaseController
  
  skip_before_filter :admin_required, :only => [:index]
  before_filter :access_to_room_management_required, :only => [:index]
  
  # Listado de responsables de sala
  def index
    @room_managers = RoomManager.order("lower(tildes(name))")
  end
  
  # Los responsables de sala han pasado a ser usuarios del sistema, por lo que su gestión está en 
  # admin/users_controller.rb. Se deja aquí el "index" para que puedan verlo los operadores de streaming
  # que no tienen acceso a la pestaña de usuarios
  # 
  # # Formulario de nuevo responsable de sala
  # def new
  #   @room_manager = RoomManager.new
  # end
  # 
  # # Crear nuevo responsable de sala
  # def create
  #   @room_manager = RoomManager.new(params[:room_manager])
  #   if @room_manager.save
  #     flash[:notice] = "El responsable se ha guardado correctamente"
  #     redirect_to admin_room_managers_path
  #   else
  #     render :action => :new
  #   end
  # end
  # Vista de datos de un responsable de sala
  # def show
  #   @room_manager = RoomManager.find(params[:id])
  # end
  # 
  # # Modificar un responsable de sala
  # def edit
  #   @room_manager = RoomManager.find(params[:id])
  # end
  # 
  # # Actualizar un responsable de sala
  # def update
  #   @room_manager = RoomManager.find(params[:id])
  #   if @room_manager.update_attributes(params[:room_manager])
  #     flash[:notice] = "El responsable se ha guardado correctamente"
  #     redirect_to admin_room_managers_path
  #   else
  #     render :action => :edit
  #   end
  # end
  
  
  
  private
  def set_current_tab
    @current_tab = :stream_flows
  end
  
  def access_to_room_management_required
    unless (logged_in? && can_access?("room_management"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end
end
