# Controlador para la administración de los áreas
class Admin::AreasController < Admin::BaseController
  
  before_filter :get_area, :except => [:index, :new, :create, :auto_complete_for_area_tag_list_es]
  
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_area_tag_list_es]
  
  cache_sweeper :footer_sweeper, :only => [ :update]
  
  def index
    @areas = Area.order('position')
  end

  def show
  end

  def new
    @area = Area.new
  end
  
  
  def create
    @area = Area.new(area_params)
    if @area.save
      flash[:notice] = "El área se ha creado correctamente"
      redirect_to admin_area_path(@area)
    else
      render :action => "new"
    end
  end
  
  def edit
  end
  
  def update
    respond_to do |format|
      if @area.update_attributes(area_params)
        flash[:notice] = "El #{@area.class.model_name.human} se ha actualizado correctamente."
        format.html { redirect_to(admin_area_path(@area)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @area.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Auto complete para los tags
  def auto_complete_for_area_tag_list_es
    auto_complete_for_tag_list(params[:area][:tag_list_es])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.nombre)}) %>"
    else
      render :nothing => true
    end    
  end


  private
  
  def set_current_tab
    @current_tab = :areas
  end
  
  def get_area
    @area = Area.find(params[:id])
  end

  def area_params
    params.require(:area).permit(:name_es, :name_eu, :name_en, :area_tag_name, :headline_keywords, 
      :description_es, :description_eu, :description_en)
  end

end
