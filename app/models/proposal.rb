# Clase para las propuestas ciudadanas
class Proposal < ActiveRecord::Base
  translates :title, :body, fallback: :any
  mount_uploader :image, ImageUploader

  attr_accessor :notify_proposer, :notify_department, :send_reject_email

  STATUS = ['pendiente', 'aprobado', 'rechazado', 'aprobado tras denuncia']
  MODERATORS = Settings.email_addresses[:proposal_moderators].split(',').collect(&:strip)

  belongs_to :user
  alias_method :author, :user

  belongs_to :department, :class_name => "Organization", :foreign_key => "organization_id"

  has_many :votes, :as => :votable, :dependent => :destroy
  has_many :notifications, -> { order("notifications.created_at") }, :as => :notifiable, :dependent => :destroy
  has_many :attachments, :as => :attachable, :class_name => '::Attachment', :dependent => :destroy, :foreign_key => 'attachable_id'

  scope :pending, -> { where("proposals.status='pendiente'").order('proposals.created_at')}
  scope :rejected, -> { where("proposals.status='rechazado'").order('proposals.created_at')}
  scope :approved, -> { where("proposals.status='aprobado'").order('proposals.created_at')}
  scope :published, ->(*args) { where(["published_at IS NOT NULL AND proposals.published_at <= ?", (args.first || Time.zone.now)])}
  scope :translated, -> { where("coalesce(title_#{I18n.locale}, '') <> '' AND coalesce(body_#{I18n.locale}, '') <> '' ")}
  scope :active, -> { joins(:department).where("active='t'")}
  scope :featured, -> { where(["featured=?", true])}

  validates_associated :user
  validates_presence_of :user_id
  validates_length_of :title_es, :title_eu, :title_en, :maximum => 255, :allow_blank => true
  validates_length_of :url, :name, :email, :maximum => 255, :allow_blank => true
  validates_format_of :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
                            :message => I18n.t('comments.blog_url_incorrect'), :allow_blank => true
  # validates_format_of :url, :with => URI::regexp(%w(http https)), :allow_blank => true
  validates_presence_of :name #, :email
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :allow_blank => true
  # Do not use validates_presence_of :area_tags
  validate :has_area_tag
  validate :validates_presence_of_any_language
  validate :cannot_approve_if_empty_department

  before_validation :set_name_and_email
  before_validation :nullify_url_if_necessary
  before_create :check_user_is_citizen
  before_save :set_notify_proposer
  before_save :set_notify_department

  include Floki
  include Tools::ActsAsArgumentable
  # preserve this order: it is necessary for WithAreaTag#sync_comments_area_tags to work
  # together with ActsAsTaggable#add_tags and ActsAsTaggable#add_tags and
  # WithAreaTag#save_tag_list_and_area_tag_list (adding tags through tag_list instead of taggings)
  acts_as_ordered_taggable
  include Tools::WithAreaTag
  include ActsAsCommentable
  # / preserve this order

  include Tools::WithPoliticiansTags
  include Sluggable

  # Preserve this order
  include DraftUtils::InstanceMethods
  before_save :sync_draft_and_published_at # definido en draft_utils.rb
  # / Preserve this order

  include Tools::Content
  include Elasticsearch::Base
  include Tools::Votable

  include Tools::QrCode
  include ExceptionRescuer
  include Tools::Clickthroughable


  # Valida que el título y el cuerpo no está vacío al menos en un idioma
  def validates_presence_of_any_language
    titles_empty = Proposal::LANGUAGES.collect {|l| l if self.send("title_#{l}").blank?}.compact
    if titles_empty.length == Proposal::LANGUAGES.length
      Proposal::LANGUAGES.each do |l|
        self.errors.add "title_#{l}", "El título no puede estar vacío" if self.send("title_#{l}").blank?
      end

    end
  end

  def cannot_approve_if_empty_department
    if self.status_changed? && self.status.eql?("aprobado") && !self.organization
      errors.add(:base, "No puedes aprobar la propuesta sin asignarle departamento antes")
    end
  end

  def organization
    department
  end

  # Indica si la propuesta está publicada
  def published?
    !published_at.nil? &&  published_at <= Time.zone.now
  end

  # Indica si la propuesta está traducida a <em>lang_code</em>, idiomas definidos en Proposal::LANGUAGES
  def translated_to?(lang_code)
    self.send("title_#{lang_code}").present? && self.send("body_#{lang_code}").present?
  end

  # Indica si la propuesta está aprobada
  def approved?
    self.status.eql?('aprobado') || self.status.eql?('aprobado tras denuncia')
  end

  # Indica si la propuesta está rechazada
  def rejected?
    status.eql?('rechazado')
  end

  # Indica si la propuesta es spam
  def spam?
    status.eql?('spam')
  end

  # Indica si la propuesta está pendiente de aprobación
  def pending?
    status.eql?('pendiente')
  end

  # Nombre de la persona que hace la propuesta
  def author_name
    self.user ? self.user.public_name : self.name
  end

  def is_public?
    !self.published_at.nil?
  end

  def approve!(params={})
    params.merge!({:status => 'aprobado', :published_at => Time.zone.now})
    self.update_attributes(params)
  end

  def reject!
    self.update_attributes(:status => 'rechazado')
    if self.send_reject_email
      email_exception {Notifier.proposal_rejection(self).deliver}
    else
      return true
    end
  end

  def notify_proposer
    @notify_proposer
  end

  # See http://thewebfellas.com/blog/2008/11/2/goodbye-attachment_fu-hello-paperclip#comment-2415
  def attachment_for name
    @_paperclip_attachments ||= {}
    @_paperclip_attachments[name] ||= Attachment.new(name, self, self.class.attachment_definitions[name])
  end

  # Para compatibilidad con los documentos.
  # Nos permite compartir el partial de attachments entre Document y Proposal
  def class_name
    self.class.to_s
  end

  # Cuerpo de la propuesta, quitando el separador de la entradilla
  def pretty_body
    body ? body.sub(/<p.*>###<.*\/p>/, '') : ""
  end

  # Indica si la propuesta tiene foto
  def has_image?
    image.present?
  end
  alias_method :has_photo?, :has_image?

  # Indica si este documento tiene documentos adjuntos
  def has_files?
    attachments.count > 0
  end

  def attached_files(lang=I18n.locale)
    self.attachments
  end

  def notify_department
    @notify_department
  end

  def to_yaml( opts = {} )
    if self.image.present?
      FileUtils.cp(self.image.path, File.join(Rails.root, 'data', 'fotos_propuestas_gov'))
    end
    YAML.quick_emit( self.id, opts ) { |out|
      out.map( taguri, to_yaml_style ) { |map|
        atr = @attributes.dup
        atr["area_tag_name"] = self.area.present? ? self.area.tag_name_es : ''
        atr["filename4photo"] = self.image.present? ? File.basename(self.image.path) : ''
        map.add("attributes",  atr)
      }
    }
  end

  private
  def set_notify_proposer
    if self.status_changed? && self.approved?
      @notify_proposer = true
    end
  end

  # Copia el nombre e email del usuario en la propuesta. Ya no es necesario. Se llama desde before_validation
  def set_name_and_email
    if self.user
      self.name = self.user.public_name
      self.email = self.user.email
      self.url = self.user.url
    end
  end

  # Si el usuario deja la URL con el valor por defecto, se quita porque no es
  # una URL válida
  def nullify_url_if_necessary
    self.url = nil if self.url.eql?("http://")
    return true
  end

  def set_notify_department
    if (self.organization_id_changed? || self.status_changed?) && self.approved?
      @notify_department = true
    end
  end

  # Sólo los usuarios que son de tipo ciudadano pueden crear propuestas ciudadanas.
  def check_user_is_citizen
    unless self.user.is_citizen?
      self.errors.add(:base, 'No puede crear propuestas ciudadanas')
      return false
    end
    true
  end

  def has_area_tag
    unless self.tag_list.detect {|t| t.match(/^_a_/)}
      self.errors.add(:area_tags, I18n.t('activerecord.errors.messages.empty'))
    end
  end


end
