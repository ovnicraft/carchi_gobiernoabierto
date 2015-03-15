# Clase para las páginas de información 
class Page < Document
  validates_presence_of :multimedia_dir
  validates_format_of :multimedia_dir, :with => /\A[a-z0-9_]+\Z/i
  validates_presence_of :organization_id
  
  before_save :set_and_create_multimedia_path  
  before_save :disable_unnecessary_fields
  
  has_one :debate, :dependent => :nullify
  include Tools::Clickthroughable
  
  class << self
    def about_pages
      [{:label => "about", :title => I18n.t('site.title', :site_name => Settings.site_name, :publisher_name => Settings.publisher[:name])},
       {:label => "tos", :title => I18n.t('site.condiciones_uso')}, 
       {:label => "privacy", :title => I18n.t('site.politica_privacidad')},
       {:label => "source_code", :title => I18n.t('site.source_code')}]
    end

    def predefined_pages
      [{:label => "legal_iphone", :title => "Aviso Legal iPhone"},
       {:label => "prop_int_iphone", :title => "Propiedad intelectual iPhone"},
       {:label => "openirekia", :title => "OpenIrekia"},
       {:label => "help", :title => "Ayuda"}]
    end

    (Page.about_pages + Page.predefined_pages).each do |page|
      define_method page[:label] do
        self.find_tagged_with("_#{page[:label]}")
      end
    end
  end
    
  def comments
    []
  end
  
  # See http://thewebfellas.com/blog/2008/11/2/goodbye-attachment_fu-hello-paperclip#comment-2415
  def attachment_for name
    @_paperclip_attachments ||= {}
    @_paperclip_attachments[name] ||= Attachment.new(name, self, self.class.attachment_definitions[name])
  end
  
  # Páginas que corresponden a Debate
  def debate_id
    self.debate.present? ? self.debate.id : nil
  end
  
  def debate_id=(d_id)
    if debate = Debate.find(d_id)
      self.debate = debate
    end
    true
  end
  
  private

    def self.find_tagged_with(tag)
      # , :scope => :private, :limit => 1
      pages = Page.tagged_with(tag)
      if pages.length > 0
        return pages.first
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    # Se usa el método definido en Tools::Multimedia
    #
    # # Crea el directorio donde irán los contenidos multimedia de esta página.
    # # Se llama desde before_create
    # def set_and_create_multimedia_path
    #   self.multimedia_path = "paginas/#{self.multimedia_dir}/"
    #   FileUtils.mkdir_p(Document::MULTIMEDIA_PATH + self.multimedia_path)
    # end
    
    # Las páginas comparten tabla con News y Event y algunas de las columnas
    # no son necesarias para las páginas. Aquí se vacían. Se llama desde before_save
    def disable_unnecessary_fields
      self.has_comments = false
      self.comments_closed = true
      self.has_comments_with_photos = false
      self.has_ratings = false
      # self.video_path = nil
      # self.audio_path = nil
      # self.photos_path = nil
      # self.files_path = nil
      self.comments_count = 0
      self.starts_at = nil
      self.ends_at = nil
      self.place = nil
      self.speaker_es = nil
      self.speaker_eu = nil
      self.speaker_en = nil
      self.lat = nil
      self.lng = nil
      self.location_for_gmaps = nil

      self.cover_photo_file_name = nil
      self.cover_photo_content_type = nil
      self.cover_photo_file_size = nil
      self.cover_photo_updated_at = nil

      self.stream_flow_id = false
      self.journalist_alert_version = 0
      self.staff_alert_version = 0
    end
    
    
end
