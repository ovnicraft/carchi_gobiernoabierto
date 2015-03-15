class Admin::SorganizationsController < Admin::BaseController
  # auto_complete_for :snetwork, :sorganization_name
  # skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_snetwork_sorganization_name]  
  
  def index
    if params[:dept_id]
      @department=Department.find(params[:dept_id])
      @sorganizations=@department.sorganizations
    else  
      @departments=Department.order('position')
      render :template => '/admin/sorganizations/departments'
    end  
  end  
  
  def new
    @department=Department.find(params[:dept_id])
    @sorganization=Sorganization.new(:department => @department)
    @sorganization.snetworks.build
  end
  
  def edit
    @sorganization=Sorganization.find(params[:id])
    @department=@sorganization.department
  end
  
  def create
    @sorganization=Sorganization.new(sorganization_params)
    @sorganization.department_id ||= params[:dept_id]
    if @sorganization.save
      flash[:notice]='Redes sociales añadidas correctamente'
      redirect_to admin_sorganizations_url(:dept_id => @sorganization.department_id)
    else
      @department=Department.find(@sorganization.department_id)
      render :action => 'new'  
    end  
  end
  
  def update
    @sorganization=Sorganization.find(params[:id])
    @sorganization.department_id ||= params[:dept_id]    
    if @sorganization.update_attributes(sorganization_params)
      flash[:notice]='Redes sociales añadidas correctamente'
      redirect_to admin_sorganizations_url(:dept_id => @sorganization.department_id)
    else
      @department=Department.find(@sorganization.department_id)
      render :action => 'edit'
    end  
  end
  
  def destroy
    @sorganization=Sorganization.find(params[:id])
    if @sorganization.destroy
      flash[:notice]='Redes sociales eliminadas correctamente'
      redirect_to admin_sorganizations_url(:dept_id => @sorganization.department_id)
    else
      flash[:error]='Error al eliminar el item'  
    end  
  end
  
  private
  
  def set_current_tab    
    @current_tab = :snetworks
  end

  def sorganization_params
    params.require(:sorganization).permit(:department_id, :name_es, :name_eu, :name_en, :icon,
      :existing_snetworks_attributes => [:url, :position, :deleted], 
      :new_snetworks_attributes => [:url, :position, :deleted])
  end
  
end  
