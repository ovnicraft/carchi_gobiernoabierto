module UsersHelper
  def users_navigation_menu_class(current)
    controller_name.eql?(current) ? 'active' : ''
  end

  def link_to_user_profile_unless_deleted(user, options={}, comment=nil)
    if [Journalist, Person, Politician].include?(user.class) && !user.public_name.eql?(I18n.t('users.eliminado'))
      link_to(h(user.public_name), path_for_user(user), options)
    else
      if comment.present? && ((User.irekia_robot && user.email.eql?(User.irekia_robot.email)) || comment.name.present?) && !user.status.eql?('eliminado')
        comment.name
      else
        h(user.public_name)
      end
    end
  end

  def am_I?(user)
    logged_in? && current_user && user && current_user.id == user.id #  && (private_profile? || politician_profile?)
  end
  
  def path_for_user(user, params = {})
    if user.is_a?(Politician)
      politician_path(user, params)
    else
      user_path(user, params)
    end
  end
  
  def default_url_title_for_user(user)
    title = if user.has_admin_access? 
      user.is_a?(RoomManager) ? t('account.mi_cuenta') : t('site.administracion')
    else
      t('account.tu_irekia', :site_name => Settings.site_name)
    end
    title
  end

end
