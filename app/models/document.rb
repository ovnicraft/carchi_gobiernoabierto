# Esta es la super clase para Noticias, Eventos y Páginas de la web. Dicho de otra forma
# News, Event y Page son subclases de Document y comparten la tabla <tt>documents</tt>
class Document < ActiveRecord::Base
  MULTIMEDIA_PATH = Rails.configuration.multimedia[:path]
  MULTIMEDIA_URL = Rails.configuration.multimedia[:url]

  translates :title, :body, :speaker

  belongs_to :organization
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_editor, :class_name => "User", :foreign_key => "updated_by"

  # has_many :attachments, :as => :attachable, :class_name => '::Attachment', :dependent => :destroy, :foreign_key => 'attachable_id'
  has_many :attachments, :as => :attachable, :class_name => 'Attachment', :dependent => :destroy, :foreign_key => 'attachable_id'
  has_many :webtv_videos, :class_name => "Video" #, :dependent => :nullify
  has_many :gallery_photos, :class_name => "Photo", :foreign_key => "document_id" #, :dependent => :nullify
  has_one :album

  has_many :recommendation_ratings, -> { order("updated_at DESC") }, :as => :source, :dependent => :destroy

  validates_presence_of :title_es
  validates_length_of :title_es, :title_eu, :title_en, :maximum => 400, :allow_blank => true
  validates_length_of :speaker_es, :speaker_eu, :speaker_en,
                      :maximum => 255 , :allow_blank => true

  scope :published, ->(*args) { where(["published_at IS NOT NULL AND published_at <= ?", (args.first || Time.zone.now)]).order("published_at DESC")}
  scope :translated, -> { where("coalesce(title_#{I18n.locale}, '') <> '' AND coalesce(body_#{I18n.locale}, '') <> '' ")}

  # Indica si un documento está publicado
  def published?
    !published_at.nil? && published_at <= Time.zone.now
  end

  def is_private?
    self.published_at.nil?
  end

  def is_public?
    !self.is_private?
  end

  alias_method :approved?, :published?

  # Preserve order of includes!
  include Sluggable

  include Tools::WithPoliticiansTags
  include Tools::Content

  # preserve this order: it is necessary for WithAreaTag#sync_comments_area_tags to work
  # together with ActsAsTaggable#add_tags and ActsAsTaggable#add_tags and
  # WithAreaTag#save_tag_list_and_area_tag_list (adding tags through tag_list instead of taggings)
  acts_as_ordered_taggable
  include Tools::WithAreaTag
  # / preserve this order

  include Elasticsearch::Base

  # Los documentos tienen contenido multimedia.
  # Los métodos relacionados con estos contenidos están definidos en el módulo Tools::Multimedia
  include Tools::Multimedia

  include Tools::QrCode

  attr_accessor :total_rating

  # Indica si un documento está traducido a <tt>lang_code</tt>
  # Los idiomas disponibles son <tt>Document::LANGUAGES</tt>
  def translated_to?(lang_code)
    self.send("title_#{lang_code}").present? && self.send("body_#{lang_code}").present?
  end

  # Quita del cuerpo del documento el separador de la entradilla <tt>###</tt>
  def pretty_body(lang_code=I18n.locale)
     send("body_#{lang_code}") ? send("body_#{lang_code}").gsub(/<p.*>###<.*\/p>/, '').gsub(/<p.*>@@@<.*\/p>/, '') : ""
  end

  before_save :disable_ratings

  # Departamento al que pertenece un documento. Solo para noticias y eventos
  def department
    dept = nil
    if self.organization
      dept = self.organization.root
    end
    dept
  end

  # def qr_code_path(locale = I18n.locale)
  #   File.join(Rails.root, "public", qr_code_url(locale))
  # end

  # def qr_code_url(locale = I18n.locale)
  #   File.join("/qr_codes/documents/#{id}","#{locale}.png")
  # end

  #
  # Fin de los métodos para compatibilidad con los demás contenidos principales
  #

  def past?
    self.published_at <= 2.days.ago
  end

  def has_cover_photo?
    self.cover_photo_file_name.present?
  end

  attr_reader :delete_cover_photo
  # Accessor para borrar la foto de portada
  def delete_cover_photo=(value)
    self.cover_photo = nil if value.to_i == 1
  end

  include DraftUtils::InstanceMethods

  before_save :sync_draft_and_published_at # definido en draft_utils.rb

  # Usamos este método cuando necesitamos el nombre de la clase "principal"
  # no el del tipo específico del documento.
  # Por ejemplo:
  # News.first.class.to_s devuelve News
  # News.first.class_name devuelve Document
  # Se usa en algunos partials compartidos entre documentos y debates
  # (por ejemplo en attachments y traducciones).
  def class_name
    "Document"
  end

  protected
  # Al principio se podía elegir si las noticias eran puntuables o no, ahora ya no lo es ninguna.
  # Aquí se desactivan las puntuaciones para todas.
  def disable_ratings
    self.has_ratings = false
    return true
  end

  # Asigna el tag del departamento al que pertenece el documento. Se llama desde before_save
  def assign_department_tag
    # self.tag_list = self.tag_list - Department.all.map {|dept| dept.tag_name}
    self.tag_list.add(self.department.tag_name) if self.department
  end

end
