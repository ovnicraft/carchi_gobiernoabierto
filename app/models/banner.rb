# Banners de la pagina de inicio
class Banner < ActiveRecord::Base
  has_attached_file :logo_es, :url  => "/uploads/banners/:id/es/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/banners/:id/es/:sanitized_basename.:extension"
  has_attached_file :logo_eu, :url  => "/uploads/banners/:id/eu/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/banners/:id/eu/:sanitized_basename.:extension"
  has_attached_file :logo_en, :url  => "/uploads/banners/:id/en/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/banners/:id/en/:sanitized_basename.:extension"

  translates :alt, :url

  MAX_FEATURED = 6
  
  #Pagination
  cattr_reader :per_page
  
  scope :active, -> { where("active='t'").order("position ASC") }
  
  before_create :set_position
  
  validates_presence_of :url_es, :alt_es
  validates_format_of :url_es, :url_eu, :url_en, :allow_blank => true, 
                      :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix , 
                      :message => 'no es correcta'
  
  validates_attachment :logo_es, presence: true, message: 'no puede estar vacío'
  
  validates_attachment_size :logo_es, :less_than => 250.kilobytes, :message => "debe tener un tamaño máximo de 250kB"
  validates_attachment_size :logo_eu, :less_than => 250.kilobytes, :message => "debe tener un tamaño máximo de 250kB"
  validates_attachment_size :logo_en, :less_than => 250.kilobytes, :message => "debe tener un tamaño máximo de 250kB"
  validates_attachment_content_type :logo_es, :message => "no es un tipo de fichero válido", 
                                    :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']
  validates_attachment_content_type :logo_eu, :message => "no es un tipo de fichero válido",
                                    :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']
  validates_attachment_content_type :logo_en, :message => "no es un tipo de fichero válido",
                                    :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']
  validate :banner_size_valid?
  
  def banner_size_valid?
    begin
      # Para cada uno de los idiomas disponibles, se comprueba si hay foto
      # y cual es su tamaño
      ['es', 'eu', 'en'].each do |lang|
        unless self.send("logo_#{lang}").tempfile.nil?
          size=Paperclip::Geometry.from_file(self.send("logo_#{lang}").tempfile.path)
          if size.width.to_i != 170 || size.height.to_i != 110
            self.errors.add("logo_#{lang}", 'debe tener un tamaño de 170x100px')
            false
          end
        end
      end
    rescue Paperclip::Errors::NotIdentifiedByImageMagickError, NoMethodError => err
      logger.error "Error checking banner size: #{err}"
    end
  end
  
  # Antes de guardar un nuevo banner, se le asigna la última posición
  def set_position
    self.position = Banner.all.map{|b| b.position}.max.to_i+1
  end
  
  def logo(locale=I18n.locale)
    self.send("logo_#{locale}")
  end  

end
