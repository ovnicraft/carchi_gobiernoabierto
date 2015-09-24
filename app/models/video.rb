# Clase para los videos de la Web TV.
#
# Nota sobre los idiomas: las columnas que determinan el idioma en el que
# está disponible el video (show_in_es, show_in_eu y show_in_en) se actualizan automáticamente
# con un cronjob que llama a Rails.root/batch_processes/check_webtv_video_languages.sh.
#
# Este proceso es necesario porque los videos se suben independientemente a través de SFTP
# sin tener que pasar por la aplicación web.
# Las columnas son necesarias para que por ejemplo en euskera, los listados solo contengan
# los videos disponibles en euskera
class Video < ActiveRecord::Base
  VIDEO_PATH = Rails.configuration.multimedia[:path]
  VIDEO_URL = Rails.configuration.multimedia[:url]

  include Sluggable
  # Los vídeos son contenido principal y salen en la lista de acciones de la parte pública de la web.
  include Tools::Content
  include Elasticsearch::Base
  include Floki

  attr_accessor :info_from_file
  # attr_accessor :duration_from_file

  include ActsAsCommentable
  belongs_to :document
  has_many :related_events, :as => :eventable, :dependent => :destroy
  has_many :events, :through => :related_events

  has_attached_file :subtitles_es,
                    :url  => "/uploads/subtitles/:id/es/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/subtitles/:id/es/:sanitized_basename.:extension"
  validates_attachment_content_type :subtitles_es, :message => "Sólo ficheros .srt", :allow_blank => true,
                                    :content_type => ['text/srt', 'application/octet-stream', 'text/plain']
  validates_attachment_file_name :subtitles_es, :matches => /srt\Z/

  has_attached_file :subtitles_eu,
                    :url  => "/uploads/subtitles/:id/eu/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/subtitles/:id/eu/:sanitized_basename.:extension"
  validates_attachment_content_type :subtitles_eu, :message => "Sólo ficheros .srt", :allow_blank => true,
                                    :content_type => ['text/srt', 'application/octet-stream', 'text/plain']
  validates_attachment_file_name :subtitles_eu, :matches => /srt\Z/

  has_attached_file :subtitles_en,
                    :url  => "/uploads/subtitles/:id/en/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/subtitles/:id/en/:sanitized_basename.:extension"
  validates_attachment_content_type :subtitles_en, :message => "Sólo ficheros .srt", :allow_blank => true,
                                    :content_type => ['text/srt', 'application/octet-stream', 'text/plain']
  validates_attachment_file_name :subtitles_en, :matches => /srt\Z/

  translates :title
  validates_presence_of :title_es, :video_path
  validates_length_of :title_es, :title_eu, :title_en, :maximum => 400, :allow_blank => true
  validates_format_of :video_path, :with => /\A[a-z0-9_\-\/]+\Z/i, :message => 'El directorio sólo puede tener letras sin tildes, números, "_", "-" y "/".<br/> Ni espacios, ni tildes, ni ñ.'

  scope :published, ->(*args) { where(["published_at IS NOT NULL AND published_at <= ?", (args.first || Time.zone.now)])}
  scope :translated, -> { where("show_in_#{I18n.locale}='t'")}
  scope :recent, ->(*args) { order("published_at DESC").limit(10)}

  # preserve this order: it is necessary for WithAreaTag#sync_comments_area_tags to work
  # together with ActsAsTaggable#add_tags and ActsAsTaggable#add_tags and
  # WithAreaTag#save_tag_list_and_area_tag_list (adding tags through tag_list instead of taggings)
  acts_as_ordered_taggable
  include Tools::WithAreaTag
  # / preserve this order

  include Tools::WithPoliticiansTags
  include Tools::Clickthroughable

  before_save :set_video_duration_and_display_format
  before_update :check_only_one_featured
  before_save :sync_mapping_with_closed_captions_category

  # Indica si el video está publicado
  def published?
    !published_at.nil? && published_at <= Time.zone.now
  end
  alias_method :approved?, :published?

  # Devuelve el listado de videos disponible para este video. Puede haber varios, uno para cada idioma.
  def videos
    videos = {}
    if video_path.present?
      videos_in_dir = Video.flv_videos_in_dir(video_path)
      Video::LANGUAGES.each do |l|
        videos[l.to_sym] = "#{video_path}_#{l}.flv" if videos_in_dir.include?(File.join(Video::VIDEO_PATH, "#{video_path}_#{l}.flv"))
      end
      videos[:common] = "#{video_path}.flv" if videos_in_dir.include?(File.join(Video::VIDEO_PATH, "#{video_path}.flv"))
      mpg_videos_in_dir = Video.mpg_videos_in_dir(video_path)
      if mpg_videos_in_dir.present?
        videos[:mpg] = {}
        ['mpg', 'mpeg', 'mov', 'mp4'].each do |ext|
          Video::LANGUAGES.each do |l|
            videos[:mpg][l.to_sym] = "#{video_path}_#{l}.#{ext}" if mpg_videos_in_dir.include?(File.join(Video::VIDEO_PATH, "#{video_path}_#{l}.#{ext}"))
          end
          videos[:mpg][:common] = "#{video_path}.#{ext}" if mpg_videos_in_dir.include?(File.join(Video::VIDEO_PATH, "#{video_path}.#{ext}"))
        end
      end 
    end
    # .reject{|k,v| k.eql?(:mpg) if v.empty?}
    return videos
  end

  # Video a mostrar, en función del idioma actual
  def featured_video
    videos[I18n.locale.to_sym] || videos[:common] || videos[I18n.default_locale.to_sym]
  end

  def featured_mpg_video
    if videos[:mpg].present?
      videos[:mpg][I18n.locale.to_sym] || videos[:mpg][:common] || videos[:mpg][I18n.default_locale.to_sym]
    end
  end

  # Indica si el video está traducido a <tt>lang</tt>
  def translated_to?(lang)
    !videos[lang.to_sym].nil? || !videos[:common].nil?
  end

  # video is translatable if there is no common version 
  def is_translatable?
    videos[:common].nil?
  end

  # Determina si este video tiene imagen para preview
  def has_cover_photo?
    File.exists?(File.join(Video::VIDEO_PATH, "{video_path}.jpg"))
  end
  # / Igual que en Document

  def is_public?
    !self.published_at.nil?
  end

  def is_private?
    !self.is_public?
  end

  include DraftUtils::InstanceMethods
  before_save :sync_draft_and_published_at # definido en draft_utils.rb

  def self.featured
    self.published.translated.where(["featured=?", true]).first || Video.published.translated.order("published_at DESC").first
  end

  # Devuelve los videos FLV que hay en el directoio <tt>path</tt>
  def self.flv_videos_in_dir(path)
    Dir.glob(File.join(Video::VIDEO_PATH, "#{path}_e[sun].flv")) + Dir.glob(File.join(Video::VIDEO_PATH, "#{path}.flv"))
  end

  def self.mpg_videos_in_dir(path)
    videos = []
    ['mpg', 'mpeg', 'mov', 'mp4'].each do |ext|
      videos << Dir.glob(File.join(Video::VIDEO_PATH, "#{path}_e[sun].#{ext}")) + Dir.glob(File.join(Video::VIDEO_PATH, "#{path}.#{ext}"))
    end
    return videos.flatten.compact
  end

  def self.categories
    Tree.find_videos_tree ? Tree.find_videos_tree.categories.roots : []
  end

  # scope :with_closed_captions, -> { where(["subtitles_#{I18n.locale}_file_name IS NOT NULL"]).order('published_at DESC')}
  def self.with_closed_captions
    Video.order('published_at DESC').select{|video| 
      (video.is_translatable? && video.send("subtitles_#{I18n.locale}_file_name").present?) || 
      (!video.is_translatable? && (video.subtitles_es_file_name.present? || video.subtitles_eu_file_name.present? || video.subtitles_en_file_name.present?))  
    }  
  end

  # Método que se usa en el bloque compartir.
  AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |lang|
    define_method "body_#{lang}" do
      ""
    end
  end

  def body
    # self.title
    ""
  end

  def current_video_file_path
    File.join(Video::VIDEO_PATH, self.featured_video.to_s)
  end

  def current_video_file_exists?
    File.exists?(current_video_file_path) && File.file?(current_video_file_path)
  end

  #
  # Transccripción del vídeo
  #
  # La generamos a partir del fichero con los subtítulos.
  #

  def transcription_available?
    self.captions_available?
  end

  # Devuelve los cuepoints del video parseando el fichero con la transcripción.
  # Si falla el parser del CSV, no se muestra de transcripción.
  def transcription
    subtitles = self.send("subtitles_#{I18n.locale}").exists? ? self.send("subtitles_#{I18n.locale}") : self.subtitles_es
    filename = subtitles.path
    cuepoints = {}
    time_regex = /(\d{2}):(\d{2}):(\d{2}),(\d{3})/
    begin
      if File.exists?(filename) && File.file?(filename)
        f = File.open(filename)
        time = nil
        text = nil
        get_text = false
        f.each do |line|
          if line.match(time_regex)
            hh,mm,ss,ms = line.scan(time_regex).flatten.map{|i| i.to_i}
            time = hh*3600 + mm*60 + ss
            cuepoints[time.to_s] = ""
            get_text = true
            next
          end
          if get_text
            cuepoints[time.to_s] += line.strip.gsub(/\.{2,}$/,'').gsub(/^\s*\.{2,}/,'').strip
          end
          if line.blank?
            get_text = false
            time = nil
          end
        end
      end
    rescue => err
      logger.error "ERROR transcripción: Video #{self.id}, fichero #{filename}, #{err}"
    end
    cuepoints
  end
  # Fin transcripción

  #
  # Subtítulos
  #
  def captions_file_name
    "#{self.featured_video}".gsub(/\.flv/,'.srt')
  end

  def captions_available?
    self.subtitles_es.exists? || self.subtitles_eu.exists? || self.subtitles_en.exists?
  end

  def captions_url(locale = I18n.locale)
    if self.captions_available?
      self.send("subtitles_#{locale}").exists? ? self.send("subtitles_#{locale}").url : self.subtitles_es.url
    else
      nil
    end
  end

  AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |locale|
    define_method "subtitles_#{locale}_to_text" do
      if self.send("subtitles_#{locale}").exists?
        srt_file = File.open(self.send("subtitles_#{locale}").path).read
        srt_match = srt_file.scan(/[0-9]*\s?\n.*\s?\n(.*[^\r])\s?\n\s?\n/)
        srt_to_text = srt_match.join.gsub(/\.{4,}/, ' ') if srt_match.present?
      end
    end
  end

  # Devuelve un array de tiempos con todas las coincidencias de la palabra
  def get_times_from_keyword(keyword, locale=I18n.locale)
    sec_values = []
    if self.send("subtitles_#{locale}").exists?
      srt_file = File.new(self.send("subtitles_#{locale}").path).read
      values = []
      keyword.split(' ').each do |kw|
        # teniendo en cuenta apariciones dentro de palabras /\s?\n(.*)\s-->\s.*[^\r]\s?\n.*\s#{kw}\s.*\s?\n/i
        values << srt_file.scan(/\s?\n(.*)\s-->\s.*[^\r]\s?\n.*#{kw}.*\s?\n/i)
      end
      values.flatten.each do |val|
        start = Time.zone.parse(val.to_s)
        sec_values << start.hour * 60 * 60 + start.min * 60 + start.sec
      end
    end
    return sec_values
  end

  # Fin subtitulos

  def info_from_file
    if current_video_file_exists?
      unless @info_from_file.present?
        begin
          @info_from_file = {}
          video_data = JSON.parse(`/usr/bin/flvmeta -j #{current_video_file_path}`)

          [:duration, :width, :height].each do |key|
              @info_from_file[key] = video_data[key.to_s].to_f.round
          end
          if (@info_from_file[:width].to_i > 0) && @info_from_file[:height].to_i > 0
            @info_from_file[:display_format] = (@info_from_file[:width].to_f / @info_from_file[:height].to_f) < 1.4 ? '43' : '169'
          end
        rescue
          logger.info "No he podido obtenerla"
        end
      end
    end

    return @info_from_file
  end

  def display_format_from_file
    info_from_file[:display_format]
  end

  def duration_from_file
    info_from_file[:duration]
  end

  # Irekia3

  # Obtener departamentos del album a partir de los tags
  def organization
    Department.where(tag_name: self.tags.all_private.map(&:name)).first
  end
  alias_method :department, :organization

  protected
    # Asegura que sólo hay un video destacado. Se llama desde before_update
    def check_only_one_featured
      Video.update_all("featured='f'") if featured && featured_changed?
    end

    # Obtiene la duración del video
    def set_video_duration_and_display_format
      if current_video_file_exists?
        if self.duration.blank?
          logger.info "Obteniendo duracion de #{current_video_file_path}"
          self.duration = self.duration_from_file
        end
        if self.display_format.blank?
          logger.info "Obteniendo formato de #{current_video_file_path}"
          self.display_format = self.display_format_from_file
        end
      end
      return true
    end

    def sync_mapping_with_closed_captions_category
      x= AvailableLocales::AVAILABLE_LANGUAGES.keys.collect {|l| self.send("subtitles_#{l.to_s}_file_name")}
      if x.uniq.compact == []
        self.tag_list.remove Category::CLOSED_CAPTIONS_TAG
      else
        self.tag_list.add Category::CLOSED_CAPTIONS_TAG
      end
    end

end
