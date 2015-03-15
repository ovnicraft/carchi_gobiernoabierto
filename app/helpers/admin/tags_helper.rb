module Admin::TagsHelper
  
  def tag_names_row_class(tag)
    tag.translated? ? "translated" : "not_translated" 
  end

  def tag_class(tag)
    if tag.name_es.match(/^_/)
      if Department.exists?(:tag_name => tag.name_es)
        "tag_departamento"
      elsif tag.name_es.match(/^_a_/)
        "tag_area"
      else
        "tag_oculto"
      end
    else
     "tag_#{tag.kind.to_s.tildes.downcase}"
   end
  end

  def show_tags_with_classes(item, show_tag_title=true, show_tag_legend=true)
    output = content_tag(:span, tags_with_kind_text(item, show_tag_legend), class: 'category_tags')
    output = output.prepend(content_tag(:b, t('tags.title')) + ': ') if show_tag_title
    content_tag(:span, output.html_safe)
  end

end
