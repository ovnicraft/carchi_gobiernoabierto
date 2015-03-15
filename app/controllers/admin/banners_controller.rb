# Controller de administracion para los banners de la pagina de inicio
class Admin::BannersController < Admin::BaseController
  cache_sweeper :footer_sweeper, :only => [ :create, :update, :destroy, :sort]
  
  # Listado de todos los banners con la imagen y el alt del idioma y el enlace
  def index
    @banners=Banner.order("active DESC, position DESC")
  end  
  
  # No se si sera necesario mostrar un banner en administracion
  def show
  end  
  
  # Crear un nuevo banner
  def new
    @banner=Banner.new
  end
  
  def create
    @banner=Banner.new(banner_params)
    if @banner.save
      flash[:notice] = "El nuevo banner se ha guardado correctamente"
      redirect_to admin_banners_path
    else
      render :action => :new
    end
  end
  
  # Actualizar los datos de un banner ya existente
  def edit
    @banner=Banner.find(params[:id])
  end
  
  def update
    @banner=Banner.find(params[:id])
    if @banner.update_attributes(banner_params)
      flash[:notice] = "El banner se ha guardado correctamente"
      redirect_to admin_banners_path
    else
      render :action => :edit
    end    
  end
  
  # Eliminar un banner
  def destroy
    @banner=Banner.find(params[:id])
    @banner.destroy
    respond_to do |format|
      format.html do
        if @banner.destroyed?   
          flash[:notice]='El banner se ha eliminado' 
        else
          flash[:error]='El banner NO se ha eliminado correctamente'
        end
        redirect_to admin_banners_path
      end
      format.js
    end
  end
  
  # Sera necesario poder ordenarlos ¿quizas drag &drop?
  def sort
    @banners=Banner.all
    @banners.each do |banner|
      new_position = params["banners-list"].reverse.index(banner.id.to_s)+1
      banner.update_attributes(:position => new_position)
    end 

    render :nothing => true
  end
  
  private
  
  def set_current_tab    
    @current_tab = :banners
  end
  
  def banner_params
    params.require(:banner).permit(:logo_es, :logo_eu, :logo_en, :url_es, :url_eu, :url_en, :alt_es, :alt_eu, :alt_en, :active)
  end

end  
