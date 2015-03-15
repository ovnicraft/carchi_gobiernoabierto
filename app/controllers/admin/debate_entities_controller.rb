class Admin::DebateEntitiesController < Admin::BaseController
  before_filter :get_debate

  #
  # Crear la relación debate-entidad.
  # Los parámetros de debate_entity contienen el nombre de la entidad: oranization_name
  # y la URL que corresponde al debate.
  #
  # Si ya existe una entidad con el nombre indicados, la asignamos. 
  # Si el nombre de la entidad no existe, creamos una nueva.
  def create
    @debate_entity = @debate.debate_entities.new(debate_entity_params)
    @debate_entity.save
    respond_to do |format|
      format.html do
        flash[:notice] = @debate.new_record? ? "La entidad no ha sido añadida al debate" : "La entidad ha sido añadida a la lista de entidades relacionadas"
        redirect_to admin_debate_path(@debate)
      end
      format.js
    end
  end
  
  def destroy
    @debate_entity = @debate.debate_entities.find(params[:id])
    @debate_entity.destroy
    respond_to do |format|
      format.html do
        if @debate_entity.destroyed?
          flash[:notice] = 'La entidad se ha eliminado correctamente de la lista de entidades relacionadas.'
        else
          flash[:error] = 'La entidad no se ha eliminado'
        end
        redirect_to admin_debate_path(@debate) 
      end  
      format.js
    end
  end
  
  # Ordenar las entidades relacionadas
  # En params[:entities_list] están los ids en el orden nuevo
  def sort
    @debate.debate_entities.each do |de|
      de.update_attribute(:position, params[:entities_list].index(de.id.to_s) + 1)
    end
    render :nothing => true
  end
  
  
  private
  
  def set_current_tab
    @current_tab = :debates
  end

  def get_debate
    @debate = Debate.find(params[:debate_id])
  end    

  def debate_entity_params
    params.require(:debate_entity).permit(:organization_name, :url_es, :url_eu, :url_en)
  end
end
