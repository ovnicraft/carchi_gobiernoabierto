# Clase para las Noticias. Es subclase de Document, por lo que usa la tabla <tt>documents</tt>
class News < Document
  translates :cover_photo_alt
  FAKE_CONSEJO_ID = 19841984
  EPUB_PATH = Rails.configuration.multimedia[:news_epub_path]

  # Las noticias, igual que los debates tienen directorio multimedia
  validates_format_of :multimedia_dir, :with => /\A(\d{4}\/\d{2}\/\d{2}\/)[a-z0-9_]+\Z/i, :allow_blank => true

  validates_presence_of :organization_id

  has_many :ratings, :as => :rateable, :dependent => :destroy

  # HT
  has_many :tweets, :class_name => "DocumentTweet", :foreign_key => "document_id", :dependent => :destroy
  # has_many :sent_tweets, -> { where("tweeted_at IS NOT NULL") }, :class_name => "DocumentTweet", :foreign_key => "document_id", :dependent => :destroy

  has_many :related_events, :as => :eventable, :dependent => :destroy
  has_many :events, :through => :related_events

  has_one :debate, :dependent => :nullify

  has_attached_file :cover_photo, :styles => Tools::Multimedia::PHOTOS_SIZES.dup,
                    :url  => "/uploads/cover_photos/:id/:style/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/cover_photos/:id/:style/:sanitized_basename.:extension"

  has_many :external_items, :class_name => "ExternalComments::Item", :foreign_key => "irekia_news_id"

  validates_attachment_size :cover_photo, :less_than => 5.megabytes
  validates_attachment_content_type :cover_photo, :content_type => ['image/jpeg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']
  validates_length_of :cover_photo_alt_es, :cover_photo_alt_eu, :cover_photo_alt_en,
                      :maximum => 255 , :allow_blank => true

  scope :listable, -> { where("consejo_news_id IS NULL") }
  scope :consejo_de_gobierno, -> { where("consejo_news_id IS NOT NULL AND consejo_news_id<>#{News::FAKE_CONSEJO_ID}") }
  
  include ActsAsCommentable
  include CachedMethods
  include Floki
  include Tools::Clickthroughable

  before_save :set_and_create_multimedia_path
  before_save :disable_unnecessary_fields
  before_save :assign_department_tag # definido en document.rb
  # HT
  # before_save :schedule_tweets
  before_update :check_only_one_a_featured
  before_update :check_only_four_b_featured
  # before_update :check_only_n_featured_bulletin
  before_update :nullify_empty_featured
  after_update :expire_featured_cache

  # See http://thewebfellas.com/blog/2008/11/2/goodbye-attachment_fu-hello-paperclip#comment-2415
  def attachment_for name
    @_paperclip_attachments ||= {}
    @_paperclip_attachments[name] ||= Attachment.new(name, self, self.class.attachment_definitions[name])
  end

  # Para euskadi.net
  def subtitle(lang_code=I18n.locale)
    if self.send("body_#{lang_code}").present? && m = self.send("body_#{lang_code}").match(/<.+class=\"r01Subtitular\".*?>(.+?)</)
      return m[1]
    else
      return ""
    end
  end

  def entradilla(lang_code=I18n.locale)
    if self.send("body_#{lang_code}").present? && m = self.send("body_#{lang_code}").match(/<.+class=\"r01Entradilla\".*?>(.+?)</)
      return m[1]
    else
      return ""
    end
  end

  def cuerpo(lang_code=I18n.locale)
    c = self.pretty_body(lang_code).dup
    if self.subtitle.present?
      c = c.gsub(/<[^<]+class="r01Subtitular".*?>#{Regexp.escape(self.subtitle(lang_code))}<\/.+?>/, '')
    end
    if self.entradilla.present?
      c = c.gsub(/<[^<]+class="r01Entradilla".*?>#{Regexp.escape(self.entradilla(lang_code))}<\/.+?>/, '')
    end

    return c
  end
  # / Para euskadi.net

  def self.ley_vivienda
    begin
      self.find(4597)
    rescue
      nil
    end
  end

  def self.most_recent
    self.published.translated.listable.includes(:organization).order("published_at DESC").limit(29)
  end

  def self.most_recent_with_image
    self.most_recent.select {|n| n.has_video? || n.has_cover_photo? || n.has_photos?}
  end

  def self.featured_a
    Rails.cache.fetch("News_featured_a_#{I18n.locale}") do
      featured_a = self.published.translated.listable.where("featured='1A'").order("published_at DESC").first

      # Si no hay ninguna, cogemos la más reciene con foto
      unless featured_a
        featured_a = self.find(self.most_recent_with_image.shift.id) if self.most_recent_with_image.length > 0
      end
      featured_a
    end
  end

  def self.featured_4b
    Rails.cache.fetch("News_featured_4b_#{I18n.locale}") do
      featured_b = self.published.translated.listable.where("featured='4B'").order("published_at DESC")
      most_recent_without_featured_1a = self.most_recent_with_image.delete_if {|n| n.id == self.featured_a.id || featured_b.include?(n)}
      featured_b = featured_b + most_recent_without_featured_1a[0..(4-featured_b.length-1)] if featured_b.length < 4
      featured_b
    end
  end

  def self.featured_bulletin
    self.published.translated.listable.where(["featured_bulletin=?", true]).order("published_at DESC")
  end

  def self.related_coefficient
    0.1
  end

  def is_consejo_news
    !consejo_news_id.nil? && consejo_news_id != News::FAKE_CONSEJO_ID
  end

  def default_multimedia_dir
    (self.published_at ? self.published_at.to_date : Date.today).to_s.gsub('-', '/') + '/'
  end

  # Noticias que corresponden a Debate
  def debate_id
    self.debate.present? ? self.debate.id : nil
  end

  def debate_id=(d_id)
    if debate = Debate.find(d_id)
      self.debate = debate
    end
    true
  end
  
  #
  # Comentarios en las noticias
  #
  
  # Obtener todos los comentarios sobre una noticia:
  # los de irekia y los de las páginas donde está importada la noticia.
  def all_comments
    comments_finder = if self.external_items.present?
      self.external_items.first.all_comments
    else
      self.comments
    end
    comments_finder
  end

  protected
    # No todas las columnas de la tabla documents se utilizan en las noticias,
    # por lo que nos aseguramos de que están vacías.
    # Se llama desde before_save
    def disable_unnecessary_fields
      self.starts_at = nil
      self.ends_at = nil
      self.place = nil
      self.lat = nil
      self.lng = nil
      self.location_for_gmaps = nil
      self.stream_flow_id = false
      self.journalist_alert_version = 0
      self.staff_alert_version = 0
    end

    # HT
    # # Programa el auto-tweeteo de las noticias publicadas en irekia, con fecha igual a la fecha de publicacion en la web.
    # # Se llama desde before_save
    # def schedule_tweets
    #   # Si ha pasado más de un mes desde su publicación, no lo twitteamos
    #   if self.published_at && self.published_at >= 1.month.ago
    #     # Primero borramos los tweets pendientes de este evento, por si ha cambiado la fecha
    #     DocumentTweet.delete_all(["document_id= ? AND tweeted_at IS NULL", self.id])
    #
    #     Event::LANGUAGES.each do |l|
    #       if self.published? && self.translated_to?(l.to_s) && !DocumentTweet.exists?(:document_id => self.id, :tweet_locale => l.to_s)
    #         self.tweets.build(:tweet_account => "irekia_news", :tweet_at => self.published_at, :tweet_locale => l.to_s)
    #       end
    #     end
    #   end
    # end

    # Garantiza que solo habrá una noticia destacada 'A' en Irekia.
    # Se llama before_update
    def check_only_one_a_featured
      if featured.eql?('1A') && featured_changed?
        Document.where("featured='1A'").update_all("featured=null")
      end
    end

    def expire_featured_cache
      if featured_changed?
        AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |l|
          Rails.cache.delete("News_featured_a_#{l}")
          Rails.cache.delete("News_featured_4b_#{l}")
        end
      end
    end
    # Garantiza que solo habrá cuatro noticias destacadas '4B' en Irekia.
    # Si hay más, se quitan las más antiguas
    # Se llama before_update
    def check_only_four_b_featured
      if featured.eql?('4B') && featured_changed?
        if News.featured_4b.length == 4
          News.featured_4b.last.update_attribute(:featured, nil)
        end
      end
    end

    # # Garantiza que solo habrá n noticias destacadas en el boletín de Irekia.
    # # Se llama before_update
    # def check_only_n_featured_bulletin
    #   if self.featured_bulletin == true && self.featured_bulletin_changed?
    #     featured = News.where(["featured_bulletin=true", true]).order("published_at DESC")
    #     if featured.length == Bulletin::MAX_FEATURED_NEWS
    #       featured.last.update_attribute(:featured_bulletin, nil)
    #     end
    #   end
    # end

    def nullify_empty_featured
      self.featured = nil if self.featured == ''
    end

  # private
  # def files_of_type(type, extension, path)
  #   files = {}
  #   if self.send("#{type}_path").present?
  #     files_in_dir = (Dir.glob(path + self.send("#{type}_path") + "_e[sun].#{extension}") + Dir.glob(path + self.send("#{type}_path") + ".#{extension}")).collect {|p| p.sub(/^#{path}/,'')}
  #     Document::LANGUAGES.each do |l|
  #       files[l.to_sym] = files_in_dir.select {|c| c.match(/_#{l}\.#{extension}$/)}
  #     end
  #     files[:common] = files_in_dir - (files[:es] + files[:eu] + files[:en])
  #   end
  #   return files
  # end

end
