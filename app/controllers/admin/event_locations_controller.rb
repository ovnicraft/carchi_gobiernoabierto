class Admin::EventLocationsController < Admin::BaseController
  
  before_filter :get_location, :except => [:index, :new, :create]
  
  def index
    @locations = EventLocation.all
  end

  def new
    @location = EventLocation.new()
  end

  def show
  end

  def edit
  end
  
  def create
    @location = EventLocation.new(event_location_params)
    if @location.save
      flash[:notice] = "El nuevo emplazamiento se ha guardado correctamente"
      redirect_to admin_event_location_path(@location)
    else
      render :action => :new
    end
  end
  
  def update
    if @location.update_attributes(event_location_params)
      flash[:notice] = "El emplazamiento se ha guardado correctamente"
      redirect_to admin_event_location_path(@location)
    else
      render :action => :edit
    end
  end
  
  private
  
  def get_location
    @location = EventLocation.find(params[:id])
  end

  def set_current_tab
    @t = "events"
    @pretty_type = t("documents.#{@t.titleize.singularize}").singularize

    @current_tab = :events
    @current_subtab = :locations
  end

  def event_location_params
    params.require(:event_location).permit(:place, :city, :address, :lat, :lng)
  end

end
