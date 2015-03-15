class Debate < ActiveRecord::Base
  MULTIMEDIA_PATH = Rails.configuration.multimedia[:path]

  translates :title, :body, :description
  include Sluggable
  MAX_FEATURED = 4

  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_editor, :class_name => "User", :foreign_key => "updated_by"

  belongs_to :department, :class_name => "Organization", :foreign_key => "organization_id"

  has_many :stages, -> { order("position") }, :class_name => "DebateStage", :foreign_key => "debate_id", dependent: :destroy
  accepts_nested_attributes_for :stages, :allow_destroy => true
  validates_associated :stages
  validate :has_at_least_one_stage_before_being_published

  has_many :debate_entities, -> { order("position") }, :dependent => :destroy
  has_many :entities, -> { order("position") }, :through => :debate_entities, :source => :organization

  has_many :attachments, :as => :attachable, :class_name => '::Attachment', :dependent => :destroy, :foreign_key => 'attachable_id'


  has_many :votes, :as => :votable, :dependent => :destroy

  # has_many :arguments, :as => :argumentable, :dependent => :destroy
  include Tools::ActsAsArgumentable

  belongs_to :page, :class_name => "Page", :foreign_key => "page_id"

  belongs_to :news, :class_name => "News", :foreign_key => "news_id"

  scope :published, ->(*args) {where(["published_at IS NOT NULL AND debates.published_at <= ?", args.first || Time.zone.now])}
  scope :translated, -> { where("coalesce(title_#{I18n.locale}, '') <> '' AND coalesce(body_#{I18n.locale}, '') <> '' ") }
  scope :featured, -> { where(:featured => true).order("published_at DESC").limit(MAX_FEATURED) }

  scope :current,  -> { where(["finished_at >= ?", Date.today]).order("finished_at") }
  scope :finished, -> { where(["finished_at < ?", Date.today]).order("finished_at DESC")}

  validates_presence_of :title_es, :hashtag
  validates_length_of :title_es, :title_eu, :title_en, :maximum => 400, :allow_blank => true

  validates_presence_of :organization_id

  validates_length_of :multimedia_dir, :maximum => 240, :allow_blank => false # dejamos sitio para poner /debates antes de multimedia_dir
  validates_format_of :multimedia_dir, :with => /\A[a-z0-9_]+\Z/i

  validates_length_of :hashtag, :maximum => 240, :allow_blank => false
  validates_uniqueness_of :hashtag, :case_sensitive => false

  before_save :set_default_image #important: always before mount_uploader, otherwise doesn't work

  mount_uploader :cover_image, DebateImageUploader
  mount_uploader :header_image, DebateHeaderUploader

  acts_as_ordered_taggable


  # Preserve this order
  include DraftUtils::InstanceMethods
  before_save :sync_draft_and_published_at # definido en draft_utils.rb
  # / Preserve this order

  include Tools::Content

  # Los debates se pueden votar
  include Tools::Votable

  # Usamos los tags para asignar área al debate
  # Preserve this order
  include Tools::WithAreaTag
  include ActsAsCommentable
  # /Preserve this order
  include Tools::WithPoliticiansTags

  # Los debates, igual que las noticias tienen directorio multimedia
  include Tools::Multimedia
  include Tools::QrCode

  include Elasticsearch::Base
  include Tools::Clickthroughable


  before_save :check_hashtag_syntax
  before_create :create_debate_tag
  after_update  :update_debate_tag
  after_save :ensure_debate_tag_exists
  
  before_save :set_and_create_multimedia_path

  before_save :set_published_at_and_finished_at
  before_update :check_only_one_featured_bulletin
  after_save :destroy_non_active_stages

  def self.featured_bulletin
    self.published.translated.where(["featured_bulletin=?", true]).order("published_at DESC")
  end

  def init_stages
    if self.stages.empty?
      DebateStage::STAGES.each_with_index do |stage, i|
        self.stages.build(:label => stage.to_s, :starts_on => Date.today + i.months, :ends_on => Date.today + (i+1).months - 1.day)
      end
    end
  end

  # Indica si un documento está publicado
  def published?
    !published_at.nil? && published_at <= Time.zone.now
  end

  # Indica si el debate es público (no está en borrador)
  def is_public?
    !self.published_at.nil?
  end

  # Indica si el debate está traducido a <tt>lang_code</tt>
  # Los idiomas disponibles son <tt>Document::LANGUAGES</tt>
  def translated_to?(lang_code)
    self.send("title_#{lang_code}").present? && self.send("body_#{lang_code}").present?
  end

  # Indica si hay foto de portada. Sólo se usa en caso de que no haya video de portada
  # Para compatibilidad con Document (se usa en Tools::Multimedia)
  def has_cover_photo?
    self.cover_image.present?
  end


  #
  # Fases del debate
  #

  # Devuelve true si la fecha de inicio de la primera fase es futura
  def future?
    self.stages.first.starts_on > Date.today
  end

  # Devuelve true si ya ha acabado la última fase
  def finished?
    #self.stages.last.ends_on < Date.today
    self.finished_at.present? ?self.finished_at.to_date < Date.today : false
  end

  # Devuelve el estado actual como objeto DebateStage
  def current_stage
    current = if self.published?
      if self.future?
        # Todavía no ha llegado la fecha de la presentación
        self.stages.first
      elsif  self.finished?
        self.stages.last
      else

        this=self.stages.detect {|s| s.starts_on <= Date.today && s.ends_on >= Date.today}
        if this.nil?
          this = self.stages.detect {|s| s.starts_on <= Date.today || s.ends_on >= Date.today}
        end
        this
      end
    else
      self.stages.first
    end
    current
  end

  # Definimos métodos para acceder a cada una de las fases.
  DebateStage::STAGES.each do |label|
    define_method("#{label}_stage") do
      self.stages.detect {|s| s.label.eql?(label.to_s)}
    end
  end

  # Fin de los métodos relacionados con las fases.

  # Para destacar una noticia en un debate hay que ponerle el tag "_destacado_<hashtag>"
  def featured_tag_name_es
    "_destacado#{self.hashtag}"
  end

  def featured_news
    News.published.tagged_with(self.featured_tag_name_es).order("published_at DESC").limit(8)
  end

  def related_news
    News.published.tagged_with(self.hashtag).order("published_at DESC").limit(8)
  end

  def leading_news
    self.featured_news.first || self.related_news.first
  end

  def approved_headlines
    Headline.published.translated.tagged_with(self.hashtag).limit(10)
  end


  # Para compatibilidad con las propuestas ciudadanas
  # (se usan cuando se muestra la información sobre un vote)
  # 2DO
  def has_comments
    true
  end
  alias_method :has_comments?, :has_comments

  def comments_closed?
    !self.stages.find_by_label('discussion').is_current?
  end

  def participation_open?
    !self.comments_closed?
  end

  def author
    self.organization
  end

  def author_name
    self.author.name
  end

  def organization
    department
  end

  # El tag del debate coincide con su hashtag (# incluido)
  # def tag_name
  #   self.hashtag
  # end

  def total_participation
    self.arguments.published.size + self.votes_count
  end

  # Para compatibilidad con los documentos.
  # Nos permite compartir partials ente Document y Debate
  # (por ejemplo el de attachments y el de traducciones)
  def class_name
    self.class.to_s
  end

  def debate_tag
    ActsAsTaggableOn::Tag.find_by_name_es(self.hashtag)
  end

  def tags_without_hashtag
    tags.all_public - [self.debate_tag]
  end

  def tag_list_without_hashtag
    @tag_list_without_hashtag ||= ActsAsTaggableOn::TagList.from(tag_list.reject {|t| t.match(self.hashtag)})
  end

  def tag_list_without_hashtag=(tag_list_without_hashtag_string)
    @tag_list_without_hashtag = ActsAsTaggableOn::TagList.from(tag_list_without_hashtag_string)
    self.tag_list = self.tag_list.select {|t| t.match(self.hashtag)} + @tag_list_without_hashtag
  end  

  private

  def has_at_least_one_stage_before_being_published
    if !self.draft && (self.stages.blank? or stages.all? {|stage| stage.marked_for_destruction? })
      self.errors.add :stages, "Debes tener al menos una fase" 
    end
  end

  def check_hashtag_syntax
    # Add # at the begining of the hashtag unless present
    if self.hashtag.match(/^\#/).nil?
      self.hashtag = '#'+self.hashtag
    end
  end  

  def create_debate_tag
    # create tag hashtag
    if self.hashtag.present? && self.debate_tag.nil?
      ActsAsTaggableOn::Tag.create(:name_es => self.hashtag, :name_eu => self.hashtag, :name_en => self.hashtag)  
    end
    self.tag_list.add(self.hashtag)
  end

  #
  # Cambiar el nombre del tag del debate si ha cambiado el hashtag.
  #
  # NOTA: Hay que hacer el cambio en un after update cuando los tags de tag_list_es ya están asignados.
  # Si se hace este cambio en un before_save, se borra el tag con el nombre viejo y se crea el nuevo.
  # Pero esto no es correcto porque se perderá la relación con los demás contenidos.
  #
  def update_debate_tag
    if self.hashtag_changed?
      old_tag_name = self.changes["hashtag"].first
      if old_tag = ActsAsTaggableOn::Tag.find_by_name_es(old_tag_name)
        # remove old_tag_name from taggable tag_list, must do it manually
        self.tag_list.remove(old_tag_name)
        new_tag_name = self.hashtag
        old_tag.update_attributes(:name_es => new_tag_name, :name_eu => new_tag_name, :name_en => new_tag_name)
        # add new_tag_name to taggable tag_list, must do it manually
        self.tag_list.add(new_tag_name)   
      end
    end
  end

  def ensure_debate_tag_exists
    if self.debate_tag.nil?
      ActsAsTaggableOn::Tag.create(:name_es => self.hashtag, :name_eu => self.hashtag, :name_en => self.hashtag)  
    end
  end

  def set_published_at_and_finished_at
    unless self.draft == "1"
      if  self.stages.length > 0
      # Si el debate no está en borrador, se asigna como fecha de publicación,
      # la fecha de inicio de la primera fase.
      self.published_at = self.stages.first.starts_on

      # Si el debate no está en borrador asignamos como feche fin
      # la fecha final de la última fase del debate.
      # Desnormalizamos este dato para facilitar el filtro por debates finalizados/activos.
      self.finished_at = self.stages.last.ends_on.to_time.end_of_day
      end
    end
    true
  end

  def destroy_non_active_stages
    self.stages.find_all {|s| !s.active}.each {|s| s.destroy} 
  end

  def set_default_image
    last_indices = (Debate.order("updated_at DESC") - [self]).map{|a| a.cover_image.url.match(/.*([0-9]).jpg/)[1] if a.cover_image.present? && a.cover_image.url.match(/default/)}.compact
    # puts "LAST INDEXES #{last_indexs.inspect}"
    index = last_indices.empty? ? 0 : last_indices.first.to_i + 1
    index = (index > 3) ? 0 : index
    # puts "INDEXXXXXXX #{index}"
    unless self.cover_image.present?
      # self.cover_image = File.open(File.join(Rails.root, 'public/images/default/', "debate_default_0#{index}.jpg"))
      self.cover_image = File.open(Rails.application.assets["default/debate_default_0#{index}.jpg"].pathname.to_s)
    end
    unless self.header_image.present?
      # self.header_image = File.open(File.join(Rails.root, 'public/images/default/', "debate_header_default_0#{index}.jpg"))
      self.header_image = File.open(Rails.application.assets["default/debate_header_default_0#{index}.jpg"].pathname.to_s)
    end
    return true
  end

  # Garantiza que solo habrá una noticia destacada 'A' en Irekia.
  # Se llama before_update
  def check_only_one_featured_bulletin
    Debate.where("featured_bulletin='t'").update_all("featured_bulletin='f'") if featured_bulletin? && featured_bulletin_changed?
  end
end
