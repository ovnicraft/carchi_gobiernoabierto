# Controlador para la administración de los equipos de las áreas
class Admin::AreaUsersController < Admin::BaseController
  before_filter :get_area, :except => [:auto_complete_for_area_user_name_and_email]
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_area_user_name_and_email]
    
  def index
  end
  
  def create
    name_and_email = params[:area_user][:name_and_email]
    email = name_and_email.strip.split('(').last.to_s.gsub(')','')
    
    if user = Politician.find_by_email(email)
      @area.area_users.create(:user_id => user.id)
    else
      flash[:error] = "No se ha añadido el nuevo miembro del equipo. No existe político con email #{email}"
    end
    
    redirect_to admin_area_users_path(:area_id => @area.id)
  end
  
  def destroy
    @area_user = @area.area_users.find(params[:id])
    if @area_user.destroy
      respond_to do |format|
        format.html { 
          flash[:notice] = 'El miembro del equipo se ha eliminado correctamente'
          redirect_to admin_area_users_path(@area) 
        }
        format.js
      end
    else
      respond_to do |format|
        format.html { 
          flash[:error] = 'El mimebro del equipo NO se ha eliminado correctamente'
          redirect_to admin_area_user_path(@area) 
        }
        format.js
      end
    end
  end
  
  # Ordenar los miembros del equipo del área
  # En params[:team] están los ids en el orden nuevo
  def sort
    @area.area_users.each do |au|
      au.update_attribute(:position, params[:team].index(au.id.to_s) + 1)
    end
    render :nothing => true
  end
  
  def auto_complete_for_area_user_name_and_email
    q = params[:area_user][:name_and_email].strip.tildes.downcase
  
    @users = Politician.where(["(status != 'ex-cargo') AND (lower(tildes(name || coalesce(last_names, '') || email)) like ?)", "%#{q}%"])  
    if @users.length > 0
      render :inline => '<%= content_tag(:ul, @users.map {|u| content_tag(:li, "#{u.public_name} (#{u.email})")}.join.html_safe) %>'
    else
      render :nothing => true
    end
  end
  
  private
  
  def set_current_tab
    @current_tab = :areas
  end
  
  def get_area
    @area = Area.find(params[:area_id])
  end
  
end
