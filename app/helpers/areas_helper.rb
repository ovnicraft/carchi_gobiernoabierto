module AreasHelper

  def areas_navigation_menu_class(current)
    current.eql?('news') && controller.controller_name.eql?('areas') ? 'active' : (controller.controller_name.eql?(current) ? 'active' : '')
  end

end
