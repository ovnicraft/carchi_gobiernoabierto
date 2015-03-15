# Clase de mapeo de álbumes con fotos
class AlbumPhoto < ActiveRecord::Base
  belongs_to :album, :counter_cache => true
  belongs_to :photo
  
  scope :ordered_by_title, -> { joins(:photo).order("cover_photo DESC, title_#{I18n.locale} DESC") }
end
