class Politician < User
  translates :public_role, :description
  alias_attribute :body, :description

  belongs_to :department

  # Los políticos forman parte del equipo de las áreas
  has_many :area_users, :foreign_key => :user_id
  has_many :areas, :through => :area_users

  has_many :followings, :dependent => :destroy, :as => :followed
  has_many :followers, :through => :followings, :source => :user
  has_many :attachments, :as => :attachable, :class_name => '::Attachment', :dependent => :destroy, :foreign_key => 'attachable_id'
  accepts_nested_attributes_for :attachments, :allow_destroy => true, :reject_if => lambda {|a| a[:file].blank?}

  after_create  :create_politician_tag
  after_save    :set_politician_tag_name
  after_save    :delete_from_area_if_type_is_not_politician

  after_destroy :change_tag_type

  scope :approved_or_ex, -> { where("status IN ('aprobado', 'ex-cargo')") }

  # Tags
  acts_as_ordered_taggable

  include Sluggable
  def title
    public_name
  end
  include Elasticsearch::Base

  def approved_or_ex?
    ['aprobado', 'ex-cargo'].include?(self.status)
  end

  def former?
    self.status.eql?('ex-cargo')
  end

  def draft
    false
  end

  def show_in_irekia?
    true
  end

  def tag
    ActsAsTaggableOn::Tag.politicians.find_by_kind_info(self.id.to_s)
  end

  def tag_name
    self.tag.present? ? self.tag.name : ''
  end

  def tag_name_es
    @tag_name_es ||= self.tag.present? ? self.tag.name_es : ''
  end

  # Para descatar una noticia para un político hay que ponerle el tag "_destacado_<tag del area>"
  def featured_tag_name_es
    "_destacado#{self.tag_name_es}"
  end


  # Redefinimos el método public_role para poder añadir "Ex-" para los excargos.
  alias_method :public_role_orig, :public_role
  def public_role
    self.former? && !self.public_role_orig.match(/^Ex-/i) ? "Ex-#{self.public_role_orig}" : self.public_role_orig
  end

  def public_name_and_role(locale = I18n.locale)
    txt = self.public_name

    role = self.send("public_role_#{locale}") || self.public_role
    txt += " (#{role})" if role.present?

    txt.strip
  end

  # Mostramos e enlace a la Guía de comunicación sólo si el político es cargo actual y tiene ID en la Guía.
  def gc_link
    if self.gc_id.present? && Rails.configuration.external_urls[:guia_uri] && !self.former?
      Rails.configuration.external_urls[:guia_uri] + "/#{I18n.locale}/people/#{self.gc_id}"
    else
      nil
    end
  end

  # Acciones del político
  include Tools::WithActions

  def published?
    self.approved?
  end

  # Propuestas de un político: las que ha hecho él
  def approved_and_published_proposals
    self.proposals.published.approved
  end

  def approved_headlines

  end

  def has_admin_access?
    self.can?('create', 'news') || self.can?('create', 'proposals') || self.can?('create', 'comments') || self.can?('approve', 'headlines')
  end

  # def can_create?(doc_type)
  #   doc_type.eql?("comments")
  # end


  # Los permisos se asignan presonalmente igual que en el caso de los miembros de Dpto.
  #
  # Indica si puede modificar recursos de tipo <tt>doc_type</tt>.
  # Los miembros de los departamentos no pueden modificar ni crear recursos compartidos.
  # Sólo tendrán acceso a la agenda privada de su departamento.
  def can_edit?(doc_type)
    case doc_type
    when 'events'
      self.can?('create_private', 'events') || self.can?('create_irekia', 'events')
    when 'comments'
      self.can?('edit', 'comments')
    else
      self.can?('edit', doc_type)
    end
  end

  # Indica si el usuario puede crear contenidos de tipo <tt>doc_type</tt>
  # Los tipos de contenido disponibles se pueden consultar en #Permission
  def can_create?(doc_type)
    case doc_type
    when 'events'
      self.can?('create_private', 'events') || self.can?('create_irekia', 'events')
    when 'comments'
      self.can?('create', 'comments') || self.can?('official', 'comments')
    else
      self.can?('create', doc_type)
    end
  end
  # /permisos


  def to_yaml( opts = {} )
    if self.photo.present?
      FileUtils.cp(self.photo.path, File.join(Rails.root, 'data', 'fotos_politicos'))
    end
    YAML.quick_emit( self.id, opts ) { |out|
      out.map( taguri, to_yaml_style ) { |map|
        atr = @attributes.dup
        atr["area_tag_names"] = self.areas.map {|a| a.tag_name_es}
        atr["area_positions"] = self.area_users.map {|au| au.position}
        atr["filename4photo"] = self.photo.present? ? File.basename(self.photo.path) : ''
        map.add("attributes",  atr)
      }
    }
  end

  private

  # Cuando se crea un político nuevo, creamos su tag
  def create_politician_tag
    tag = create_new_politician_tag()
    # self.tag_list_es = tag.name
    self.tag_list = tag.name
  end

  # Si ha cambiado el nombre del político, cambiamos el nombre del tag correspondiente para que siempre sean iguales.
  # Si ha cambiado el tipo del usuario y este ya no es político, cambiamos el tipo del tag.
  # Si ha cambiado el tipo de usuario de uno que no es político a político, creamos el tag.
  def set_politician_tag_name
    if self.name_changed? || self.last_names_changed?
      if self.tag.present?
        new_name = self.public_name
        self.tag.update_attributes(:name_es => new_name, :name_eu => new_name, :name_en => new_name)
      end
    end

    if self.type_changed?
      if self.type != "Politician"
        change_tag_type
      end
    end
  end

  # Si se elimina el político y hay contenidos con su tag, cambiar el tipo del tag.
  # Si no hay contenidos acts_as_taggable se ocupará de eliminar el tag.
  def change_tag_type
    if tag2change = self.tag
      tag2change.update_attributes(:kind => nil, :kind_info => nil)
    end
  end

  # Si ha cambiado el tipo del usuario y éste ya no es político, no puede estar dentro del equipo de un área.
  # Si estaba en algún equipo, lo quitamos.
  def delete_from_area_if_type_is_not_politician
    if self.type_changed?
      if self.type != "Politician"
        self.area_users.destroy_all
      end
    end
  end

  private
  # Vacia los campos irrelevantes para este tipo de usuario.
  # Se llama desde before_save
  def reset_unnecessary_fields
     self.raw_location = nil
     self.lat = nil
     self.lng = nil
     self.city = nil
     self.state = nil
     self.country_code = nil
     self.zip = nil
     self.url = nil
     self.media = nil
     self.organization = nil
  end


end
