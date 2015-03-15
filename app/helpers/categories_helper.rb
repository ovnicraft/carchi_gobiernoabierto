module CategoriesHelper
  
  def link_to_category(category)
    name, url, options = category_name_and_url(category)
    if url.eql?('#')
      "<span>#{name.sub(/\+$/, '')}</span>"
    else
      link_to h(name), url, options
    end
  end                            
  
  def menu_item_class(category, current_category, mark_ancestors=true)
    output = "passive"
    if current_category 
      ancestor_ids = current_category.ancestors.collect(&:id)
      if category.id == current_category.id 
        return "active"
      end
      if mark_ancestors && ancestor_ids.include?(category.id) 
        return "active"
      end
    end
    return output
  end
    
  def css_class_for(category)
    if m = category.name_es.match(/\"(.+)\":/)
      m[1].downcase.gsub(/[^a-z]/i, '')
    else
      category.name_es.downcase.gsub(/[^a-z]/i, '')
    end
  end
  
end
