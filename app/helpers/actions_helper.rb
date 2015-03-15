module ActionsHelper
  
  def actions_menu_option_class(option_controller_name)
    selected  = case controller.controller_name 
      when 'news', 'events', 'videos'
        option_controller_name.eql?('actions')
      when 'proposals'
        option_controller_name.eql?('proposals_citizens')
      else
        controller.controller_name.eql?(option_controller_name)
      end
    
    selected ? "selected" : "passive"
  end
    
    
  def actions_list_filter_link(opts)
    content_type = opts[:content_type]
    content_type = 'news_index' if content_type.eql?(:news) && !opts[:context_id].present?
    link = if opts[:context_id]
      send("#{opts[:context_prefix]}#{content_type}_path", "#{opts[:context_prefix]}id" => opts[:context_id], :filter => opts[:filter])
    else
      send("#{opts[:context_prefix]}#{content_type}_path", :filter => opts[:filter])
    end
    
    link
  end
end
