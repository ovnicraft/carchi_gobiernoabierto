# Clase para los álbums de la fototeca
class Album < ActiveRecord::Base
  translates :title
  include Sluggable

  has_many :album_photos, :dependent => :destroy
  # I cannot put :order clause here because nested order clauses are not working with scope
  # and I'm most interested in using this as <tt>album.photos.ordered_by_title</tt>
  has_many :photos, :through => :album_photos
  belongs_to :document

  validates_presence_of :title_es
  validates_length_of :title_es, :maximum => 255
  validates_length_of :title_eu, :title_en, :maximum => 255, :allow_blank => true

  acts_as_ordered_taggable

  include Tools::WithAreaTag
  include Tools::WithPoliticiansTags
  include Tools::Clickthroughable

  scope :published, -> { where("draft='f'").order("created_at DESC") }
  scope :with_photos,  -> { where("album_photos_count>0").order("created_at DESC") }
  scope :featured, -> { where("featured='t'").order("created_at DESC") }

  # # Versión corta del título para que quepa en la portada del álbum
  # def title_for_cover
  #   title.length > 50 ? title[0..48].sub(/\s[^\s]+$/, ' ...') : title
  # end

  # Los vídeos son contenido principal y salen en la lista de acciones de la parte pública de la web.
  include Tools::Content

  # Foto de portada para este album
  def cover_aphoto
    @cover_aphoto ||= (album_photos.find_by_cover_photo(true) || album_photos.first)
  end

  def cover_photo
    cover_aphoto.photo if cover_aphoto
  end

  def first_photo
    self.photos.order("date_time_original").first
  end

  def last_photo
    self.photos.order("date_time_original DESC").first
  end

  def published_at
    self.updated_at
  end

  def has_cover_photo?
    cover_aphoto.present?
  end

  include Elasticsearch::Base

  # Determina si el álbum se muestra en Irekia.
  # Sólo relevante para la busqueda
  def is_public?
    !draft?
    # true
  end

  def published?
    !draft?
  end
  alias_method :approved?, :published?

  # para poder reusar /documents/_share
  def body
    ""
  end

  # Obtener departamentos del album a partir de los tags
  def organization
    Department.where(:tag_name => self.tags.all_private.map(&:name)).first
  end
  alias_method :department, :organization

  def self.categories
    Tree.find_albums_tree ? Tree.find_albums_tree.categories.roots : []
  end
end
