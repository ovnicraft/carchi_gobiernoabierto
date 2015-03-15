module PoliticiansHelper
  
  # Indica si hay que mostrar el link "Haz una pregunta" o no para un político.
  # Lo usamos durante el cambio de legislatura para esconder este enlace en la página de los políticos
  # mientras se hacen los cambios en los cargos y evitar que se hagan preguntas a políticos que van a dejar el cargo.
  def show_politician_create_question?(politician)
    # Original
    # politician.nil? || politician.approved?
    
    # Temporalmente desactivamos el enlace (ticket #3673)
    politician.present? ? false : true
  end

  def politicians_navigation_menu_class(current)
    current.eql?('news') && controller_name.eql?('politicians') ? 'active' : (controller.controller_name.eql?(current) ? 'active' : '')
  end
    
end
 