# encoding: UTF-8
module Admin::PhotosHelper
  
  def available_albums_as_options_for(photo)
    # "<option value=''>Añadir al álbum...</option>" + \
    # options_for_select((Album.order("title_es") - photo.albums).collect {|a| [a.title, a.id]})
    
    xx = content_tag(:option, :value => "") {"Añadir al album..."}
    Album.order("title_es").each do |album|
      if photo.album_ids.include?(album.id)
        xx << content_tag(:option, :value => album.id, :disabled => true) {album.title}
      else
        xx << content_tag(:option, :value => album.id) {album.title}
      end
    end
    return xx
  end
end
