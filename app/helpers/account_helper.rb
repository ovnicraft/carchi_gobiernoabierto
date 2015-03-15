module AccountHelper
  def icon_for_comment(comment)
    case comment.commentable
    when News
      "noticias"
    when Event
      "agenda"
    when Proposal
      "propuestas"
    end
  end

  def account_navigation_menu_class(current)
    action_name.eql?(current) ? 'active' : ''
  end

end
