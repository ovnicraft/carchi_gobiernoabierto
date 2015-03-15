module NewsHelper
    
  def render_rss_enclosure(document)  
    {"url" => url_to_attachment(document.cover_photo.url), "length" => document.cover_photo_file_size, "type" => document.cover_photo_content_type} 
  end  
  
  def url_to_attachment(attach_path)
    request.protocol + request.host_with_port + attach_path.gsub(/.*(\?[0-9]*)/){|a| a.gsub($1, '')}
  end
  
  def show_toggle_carousel_links(item)
    content_tag(:div, link_to(content_tag(:span, '', :class => 'arrow') + t("documents.esconder_#{item}"), "#", :onclick => "$('div.thumb_viewer_carousel.#{item}').slideToggle();$('.hide_#{item}').toggle(); $('.show_#{item}').toggle();return false;"), :class => "hide_#{item} x_hide") +
    content_tag(:div, link_to(content_tag(:span, '', :class => 'arrow') + t("documents.ver_#{item}"), "#", :onclick => "$('div.thumb_viewer_carousel.#{item}').slideToggle();$('.hide_#{item}').toggle(); $('.show_#{item}').toggle();return false;"), :class => "show_#{item} x_show", :style => 'display: none')        
  end
  
  def get_photo_size(photo)
    begin
      photo_path = photo.respond_to?('url') ? photo.path : photo
      size = Paperclip::Geometry.from_file(photo_path).to_s.split('x')
    rescue
      size = [0,0]  
    end
  end

  def get_photo_orientation(photo)
    size = get_photo_size(photo)
    if size[0] > size[1]
      'landscape'
    else
      'portrait'
    end
  end
  
end
