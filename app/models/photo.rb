# Clase para las fotos de la fototeca
class Photo < ActiveRecord::Base
  PHOTOS_PATH = Rails.configuration.multimedia[:path]
  PHOTOS_URL = Rails.configuration.multimedia[:url]

  has_many :album_photos, :dependent => :destroy
  has_many :albums, :through => :album_photos
  belongs_to :document

  validates_presence_of :title_es, :title_eu, :title_en, :file_path, :on => :create
  validates_uniqueness_of :file_path
  validates_length_of :title_es, :title_eu, :title_en, :city, :province_state, :country, :maximum => 255, :allow_blank => true
  validates_format_of :dir_path, :with => /\A[a-z0-9_\/]+\Z/i, :message => 'El directorio sólo puede tener letras sin tildes, números, "_" y "/".<br/> Ni espacios, ni tildes, ni ñ.', :on => :create

  # Para poder validar que al importar las fotos ponen un directorio sin espacios ni tildes
  attr_accessor :dir_path

  scope :ordered_by_title, -> {order("title_#{I18n.locale} DESC")}
  scope :published, -> { joins(:albums).where(["albums.draft=?", false])}

  include Floki

  acts_as_ordered_taggable

  include Tools::WithAreaTag

  translates :title

  def date
    date_time_original || created_at
  end

  # Devuelve la versión de tamaño <em>size</em> de la foto actual.
  # ==== Parámetros
  # * <tt>size:</tt> tamaño deseado. Los valores permitidos son los keys de Tools::Multimedia::PHOTOS_SIZES, definido en el módulo #PhotoPaths
  # * <tt>path:</tt> no se usa
  def version(size=:n70, path=:absolute)
    if Tools::Multimedia::PHOTOS_SIZES.keys.include?(size)
      #version_path = "#{File.dirname(File.join(self.file_path, size.to_s, File.basename(self.file_path)))}"
      version_path = File.join(File.dirname(self.file_path), size.to_s, File.basename(self.file_path))
    else
      version_path = self.file_path
    end
    if path.eql?(:absolute)
      return File.join(Photo::PHOTOS_URL, version_path)
    else
      return version_path
    end
  end

  def is_public?
    true
  end

  # Indica si la foto está publicada. Lo está si está en algún album publicado
  def published?
    albums = self.albums
    albums.length > 0 && albums.collect(&:draft).include?(false)
  end

  def draft?
    !published?
  end
  alias_method :draft, :draft?

  # Para poder reusar /documents/_share
  def body
    ""
  end

  # Should try to use Paperclip::Geometry instead
  # returns [width, height], if possible
  def geometry_from_file
    file = File.join(Photo::PHOTOS_PATH, version(:original, :relative))
    geometry = begin
                 Paperclip.run("identify", %Q[-format "%wx%h" "#{file}"])
               rescue => err
                 logger.info "No he podido coger las dimensiones de #{self.id}: #{err}"
                 ""
               end
    if match = (geometry.match(/\b(\d*)x?(\d*)\b([\>\<\#\@\%^!])?/))
      match.to_a[1,2]
    else
      logger.info "No he podido coger las dimensiones de #{self.id}: #{geometry}"
      ""
    end
    # parse(geometry) ||
    #   raise(NotIdentifiedByImageMagickError.new("#{file} is not recognized by the 'identify' command."))
  end

  # True if the dimensions represent a square
  def square?
    height == width  if !(width.blank? && height.blank?)
  end

  # True if the dimensions represent a horizontal rectangle
  def horizontal?
    height < width if !(width.blank? && height.blank?)
  end

  # True if the dimensions represent a vertical rectangle
  def vertical?
    height > width if !(width.blank? && height.blank?)
  end

  def orientation
    self.vertical? ? 'portrait' : 'landscape'
  end

  # The aspect ratio of the dimensions.
  def aspect
    width.to_f / height.to_f if !(width.blank? && height.blank?)
  end

  before_save :set_geometry
  def set_geometry
    self.width, self.height = self.geometry_from_file
  end

end
