# Controlador para la administración de departamentos y organismos
class Admin::OrganizationsController < Admin::BaseController
  before_filter :department_or_organization, :only => [:new, :create]

  # Listado de departamentos
  def index
    @organizations = Organization.where("parent_id IS NULL").order("position")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @admin_organizations }
    end
  end

  # Vista de un departamento
  def show
    @organization = Organization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # Formulario de nuevo departamento
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # Modificar departamento
  def edit
    @organization = Organization.find(params[:id])
  end


  # Crear departamento
  def create
    @organization.attributes = organization_params

    respond_to do |format|
      if @organization.save
        flash[:notice] = "El #{@organization.class.model_name.human} se ha creado correctamente."
        format.html { redirect_to(admin_organization_path(@organization)) }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualizar departamento
  def update
    @organization = Organization.find(params[:id])

    respond_to do |format|
      if @organization.update_attributes(organization_params)
        flash[:notice] = "El #{@organization.class.model_name.human} se ha actualizado correctamente."
        format.html { redirect_to(admin_organization_path(@organization)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # # Eliminar departamento
  # def destroy
  #   @organization = Organization.find(params[:id])
  #   @organization.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(admin_organizations_url) }
  #     format.xml  { head :ok }
  #   end
  # end
  
  private
  def set_current_tab
    @current_subtab = :organization
    @current_tab = :depts
  end
  
  def department_or_organization
    @organization = params[:d] && params[:d].to_i == 1 ? Department.new : Organization.new
  end

  def organization_params
    params.require(:organization).permit(:name_es, :name_eu, :name_en, :active, :tag_name, :term, :parent_id, :gc_id)
  end
end
