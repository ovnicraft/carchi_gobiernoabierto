module Admin::AlbumsHelper
  def album_options
    options = "<option value='0'>Nuevo album</option>" 
    Album.order("title_es").each do |a| 
      if params[:album_id].present? && params[:album_id].to_i == a.id
        options << "<option value='#{a.id}' selected='selected'>#{shorten(a.title_es)}</option>"
      else
        options << "<option value='#{a.id}'>#{shorten(a.title_es)}</option>"
      end
    end
    return options.html_safe
  end
end
