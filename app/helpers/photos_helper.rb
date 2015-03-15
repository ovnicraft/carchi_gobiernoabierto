# encoding: UTF-8
module PhotosHelper
  def shorten(title, length=65)
    # We use length-4 because are going to add "... "
    title.length > length ? "#{truncate(title, :length =>  length-4, :omission => "").sub(/[^\w]\w+$/, '')}&#8230; ".html_safe : title
  end
  
  def aspect(photo)
    case 
    when photo.vertical?
      "vertical"
    when photo.square?
      "square"
    else
      "horizontal"
    end
  end

  def photo_width(photo, size)
    if photo.width.present?
      size = size.to_s.gsub(/[^\d]/, '').to_f 
      if photo.horizontal?
        width = size.to_i
      else
        width = (size*photo.aspect).round
      end
    end
  end

  def photo_height(photo, size)
    if photo.height.present?
      size = size.to_s.gsub(/[^\d]/, '').to_f 
      if photo.vertical?
        height = size.to_i
      else
        height = (size/photo.aspect).round
      end
    end
  end
  
end
