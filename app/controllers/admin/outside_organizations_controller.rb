# Controlador para las entidades relacionadas con los debates
class Admin::OutsideOrganizationsController < Admin::BaseController
  
  def index
    @title = "Propuestas del Gobierno"
    @organizations = OutsideOrganization.paginate(:per_page => 20, :page => params[:page]).order('name_es')
  end
  
  def new
    @title = "Nueva entidad relacionada para las propuestas del Gobierno"
    @organization = OutsideOrganization.new()
  end
  
  def create
    @title = "Nueva entidad relacionada para las propuestas del Gobierno"
    @organization = OutsideOrganization.new(outside_organization_params)

    if @organization.save()
      flash[:notice] = 'Los datos de la entidad se han guardado correctamente'
      redirect_to admin_outside_organizations_path()
    else
      render :action => 'new'
    end    
  end
  
  def edit
    @title = "Modificar entidad relacionada para las propuestas del Gobierno"
    @organization = OutsideOrganization.find(params[:id])
  end
  
  def update
    @title = "Modificar entidad relacionada para las propuestas del Gobierno"
    @organization = OutsideOrganization.find(params[:id])
    if @organization.update_attributes(outside_organization_params)
      flash[:notice] = 'Los datos de la entidad se han guardado correctamente'
      redirect_to admin_outside_organizations_path()
    else
      render :action => 'edit'
    end    
  end
  
  def destroy
    @organization = OutsideOrganization.find(params[:id])
    if @organization.destroy
      flash[:notice] = "La entidad se ha eliminado"
      redirect_to admin_outside_organizations_path()
    else
      @title = "Modificar entidad relacionada para las propuestas del Gobierno"
      render :edit
    end
  end
  
  private
  
  def set_current_tab
    @current_tab = :debates
  end

  def outside_organization_params
    params.require(:outside_organization).permit(:name_es, :name_eu, :name_en, :logo, :remove_logo, :logo_cache)
  end
  
end
