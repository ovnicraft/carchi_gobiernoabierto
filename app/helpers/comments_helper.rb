module CommentsHelper
  
  def comment_style(comment)
    if comment.user_id && comment.is_official?
      'official_comment'
    else
      'citizen_comment'
    end
  end
  
  def show_comment_author_name(comment)
    if User.irekia_robot && comment.email.eql?(User.irekia_robot.email)
      comment.name
    else
      comment.author.public_name if comment.author
    end
  end

  def link_to_item_comments(count, item=nil, options={})
    item_comments_url = if item.present?
      send("#{item.class.to_s.downcase}_path", item, :anchor => '#acomments')
    else
      '#acomments'
    end
    content_tag(:div, link_to(count, item_comments_url, options.merge(:class => 'comments_count')), :class => "comments_link rs_skip donotprint")
  end

  def path_to_commentable(commentable, url_for_options={})
    if commentable.is_a?(ExternalComments::Item)
      commentable.url
    else
      send("#{commentable.class.to_s.downcase}_path", commentable, url_for_options)
    end
  end
  
  def url_to_commentable(commentable, url_for_options={})
    if commentable.is_a?(ExternalComments::Item)
      commentable.url
    else
      send("#{commentable.class.to_s.downcase}_url", url_for_options.merge(id: commentable.id))
    end    
  end
end
