# Clase que engloba todos los tipos de usuario. Los diferentes tipos son subclase de esta clase.
# Aquí se definen todos los métodos comunes para todos los tipos de usuario, y luego se
# sobreescriben en la subclase correspondiente, para aquellos tipos en los que el comportamiento
# por defecto no es válido
require 'digest/sha1'
class User < ActiveRecord::Base
  include ExceptionRescuer

  has_many :arguments, :dependent => :destroy
  has_many :comments, -> { order("created_at DESC") }, :dependent => :nullify
  has_many :proposals
  has_many :votes, :dependent => :destroy

  # has_many :subscriptions, :dependent => :destroy

  has_many :permissions, :dependent => :destroy
  has_many :session_logs, :dependent => :destroy
  has_many :event_alerts # no pongo :dependent => :destroy porque solo queremos borrar las que aun no se han enviado

  # oauth-plugin
  has_many :client_applications
  has_many :tokens, -> { order("authorized_at desc")}, :class_name=>"OauthToken"
  # DEPRECATED: , :include=>[:client_application] 
  # /oauth-plugin

  has_many :followings
  has_many :following_areas, :through => :followings, :source => :followed, :source_type => 'Area'
  has_many :following_politicians, :through => :followings, :source => :followed, :source_type => 'Politician'

  has_many :notifications, :dependent => :destroy
  has_many :bulletin_copies, :dependent => :destroy

  mount_uploader :photo, PhotoUploader

  # Estados de los usuarios:
  # pendiente: el usuario se ha dado de alta y no ha confirmado su registro (para ciudadanos que se registran desde la web)
  # aprobado: el usuario se ha dado de alta y ha confirmado su registro (para los ciudadadanos)
  #           o los admin han cambiado su estado (para los demás usuarios)
  # vetado: los admin han vetado el acceso del usuario.
  #         Si es político, en la web no sale ni su página de político ni él sale en el equipo de área al que está asignado.
  #         Este usuario no puede logearse en la web
  #  eliminado: un ciudadanno que se ha dado de baja (ha eliminado su perfil).
  #             Se ven los contenidos que él ha creado pero no salen sus datos personales
  # ex-cargo: político que ya no está en el cargo que ocupaba.
  #           Sale su página y su actividad pero no se le pueden hacer preguntas ni se le puede seguir
  User::STATUS = %w(pendiente aprobado vetado eliminado ex-cargo)

  User::TYPES = {'Person' => 'Registrado', 'Journalist' => 'Periodista', 'Politician' => 'Político',
    'Admin' => 'Administrador', 'Colaborator' => 'Colaborador', 'User' => 'Todo',
    'DepartmentEditor' => 'Jefe de prensa', 'StaffChief' => 'Jefe de gabinete', 'DepartmentMember' => 'Miembro de departamento',
    'StreamingOperator' => 'Operador de streaming', 'RoomManager' => "Responsable de sala", 'ExternalColaborator' => 'Colaborador externo'}

  # Usuarios que se consideran personal de Lehendakaritza
  User::STAFF = %w(Admin DepartmentEditor StaffChief)

  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :old_password

  validates_presence_of     :email,                      :unless => Proc.new {|user| user.is_twitter_user? || user.is_facebook_user? || user.is_googleplus_user?}
  validates_presence_of     :name
  validates_presence_of     :type
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  # validates_length_of       :email,    :within => 3..100,:unless => :email_blank
  validates_uniqueness_of   :email,                      :case_sensitive => false, :unless => :email_blank
  validates_format_of       :email,                      :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :unless => :email_blank
  validates_format_of       :bulletin_email,                      :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :unless => Proc.new{|user| user.bulletin_email.blank?}
  validates_format_of :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix , :message => I18n.t('comments.blog_url_incorrect'), :allow_blank => true
  # validates_format_of       :url,                        :with => URI::regexp(%w(http https)), :allow_blank => true
  validate :old_password_is_correct

  scope :approved, -> { where("status='aprobado'")}
  scope :pending, -> { where("status='pendiente'")}
  # This should be in politician.rb but then we couldn't use area.users.with_agenda
  scope :with_agenda, -> { where(["politician_has_agenda=?", true])}
  scope :wants_bulletin, -> { where(["wants_bulletin=? AND (coalesce(bulletin_email, '') <> '' || coalesce(email, '') <> '')", true])}

  before_save :reset_unnecessary_fields
  before_save :encrypt_password
  before_create :set_default_status
  before_validation :nullify_url_if_necessary
  before_save :reset_permissions_if_role_changed
  before_destroy :destroy_pending_alerts

  after_save :create_tag_if_changed_to_politician

  after_save :reset_official_commenters
  after_destroy :reset_official_commenters

  def self.irekia_robot
    find_by_email("sn@open.irekia.net")
  end

  # Devuelve un array con los tipos de usuarios que pertenecen a algún departamento
  def self.with_department
    User::TYPES.select {|k, v| k.constantize.new.has_department?}.collect {|u| u[0].to_s}
  end

  # Autentifica al usuario por su email, status y contraseña. Devuelve el usuario o nil.
  def self.authenticate(email, password)
    
    u = User.find_by(email: email, status: 'aprobado') # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Autentifica al usuario por su id y contraseña encriptada. Devuelve el usuario o nil
  def self.authenticate_from_url(user_id, crypted_password)
    u = User.find_by(id: user_id, status: "aprobado", crypted_password: crypted_password)
  end

  cattr_accessor :official_commenters
  def self.official_commenters
    # This is expensive, so we memoize it. Memo will be flushed if there is a user type change
    # or a permission is changed.
    # Note: class variable localization only works in production by default
    # http://stackoverflow.com/questions/9720520/do-ruby-class-variables-get-cleared-between-rails-requests
    @@official_commenters ||= User.approved.select {|u| u.is_official_commenter?}
    # @@official_commenters = [User.find(4067)]
  end

  # Nombre tal y como aparecerá en las páginas públicas
  def public_name
    if name.eql?('deleted')
      I18n.t('users.eliminado')
    else
      [name, last_names].compact.join(" ")
    end
  end

  # Nombre interno, principalmente para el "staff" que tiene nombres públicos
  # con los que no se les puede identificar fácilmente
  def internal_name
    internal_name = public_name
    internal_name << " (#{telephone})" unless telephone.blank?
    return internal_name
  end

  # Encripta los datos con el salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encripta la contraseña con el salt del usuario
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  # Determina si el usuario está autentificado
  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.zone.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for(2.weeks)
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(validation:false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(validation:false)
  end

  def is_admin?
    self.is_a?(Admin)
  end

  def is_citizen?
    self.is_a?(Person) || self.is_a?(Journalist)
  end

  def published?
    self.status.eql?('aprobado')
  end

  def bulletin_email
    self.is_outside_user? ? super : self.email
  end

  # Indica si tiene permiso para acceder a la administración de los recursos de tipo <tt>doc_type</tt>. Por defecto,
  # sólo los usuarios de tipo Admin pueden acceder a todos los módulos. En las subclases se concretan los permisos
  # para cada tipo de usuario
  # ==== Ejemplos:
  # - current_user.can_access?("news")
  # - current_user.can_access?("photos")
  def can_access?(doc_type)
    if doc_type.eql?("users")
      can?("administer", "permissions")
    else
      [Admin].include?(self.class)
    end
  end

  # Indica si puede modificar recursos de tipo <tt>doc_type</tt>. Por defecto, sólo los usuarios de tipo Admin
  # pueden modificar todos los módulos. En las subclases se concretan los permisos para cada tipo de usuario.
  # ==== Ejemplos:
  # - current_user.can_edit?("news")
  # - current_user.can_edit?("photos")
  def can_edit?(doc_type)
    [Admin].include?(self.class)
  end

  # Indica si puede crear recursos de tipo <tt>doc_type</tt>. Por defecto, sólo los usuarios de tipo Admin
  # pueden modificar todos los módulos. En las subclases se concretan los permisos para cada tipo de usuario.
  # ==== Ejemplos:
  # - current_user.can_create?("news")
  # - current_user.can_create?("photos")
  def can_create?(doc_type)
    [Admin].include?(self.class)
  end

  # Indica si el usuario es miembro del "staff"
  def is_staff?
    User::STAFF.include?(self.class.to_s)
  end

  # Indica si puede acceder a alguna de las secciones de la administracion
  def has_admin_access?
    self.is_staff? || ["Colaborator", "StreamingOperator", "DepartmentMember", "RoomManager"].include?(self.class.to_s) || (self.is_a?(ExternalColaborator) && self.permissions.present?)
  end

  # Indica si los comentarios de este usuario se consideran oficiales y, por lo tanto,
  # se aprueban automáticamente y se muestran en color destacado
  def is_official_commenter?
    self.is_staff? || self.can?('official', 'comments')
  end

  # Indica si se debe especificar departamento para este usuario
  def has_department?
    self.respond_to?("department")
  end

  # Devuelve un array de los organismos a los que está suscrito. Sólo relevante para periodistas
  def organization_ids
    []
  end

  # Indica si el colaborador tiene permiso de tipo <tt>perm_type</tt> en los contenidos de tipo <tt>doc_type</tt>.
  # Los tipos de contenidos y los correspondientes permisos se pueden consultar en #Permission
  # ==== Ejemplos:
  # - current_user.can?("create", "news")
  # - current_user.can?("administer", "permissions")
  def can?(perm_type, doc_type)
    # Admin tiene permiso para todo menos para gestionar usuarios y repartir permisos
    if self.is_a?(Admin) && !%w(users permissions).include?(doc_type)
      true
    elsif (![DepartmentMember, Politician].include?(self.class)) && doc_type.eql?("events") &&  %w(create_irekia create_private).include?(perm_type)
      # Los permisos para publicar noticias en irekia, agencia y privados, solo se ponen para los miembros
      # de departamento y políticos. Para los demas, el permiso es el mismo de crear evento
      self.can_create?(doc_type)
    else
      permission?(perm_type, doc_type)
    end
  end

  # Indica si el usuario tiene permiso de tipo <tt>perm_type</tt> en el modulo <tt>doc_type</tt>.
  # Para ver los valores posibles de estas dos variables, ver el comentario inicial de la clase Permission
  def permission?(perm_type, doc_type)
    conditions = ["module=?", doc_type]
    case
    when perm_type.eql?("edit")
      # El permiso de crear lleva consigo el de modificar
      conditions[0] << " AND action IN ('edit', 'create')"
    when !perm_type.eql?("access")
      # access significa cualquier tipo de permiso sobre el modulo
      conditions[0] << " AND action=?"
      conditions << perm_type
    end
    permissions.exists?(conditions)
  end

  # Devuelve un array con todos los permisos que tiene un usuario
  # Incluye:
  # * Los permisos heredados del tipo de usuario
  # * Los permisos dados manualmene a través de la clase #Permission
  def all_permissions
    fp = self.permissions.dup

    if self.class.respond_to?("inherited_permissions")
      self.class.inherited_permissions.each do |perm|
        fp << Permission.new(perm.merge(:editable => false, :user_id => self.id))
      end
    end
    return fp
  end

  # Devuelve un hash con todos los permisos de este usuario, tanto los heredados por el role como los
  # obtenidos a traves de Permission.
  # Formato:
  #   <tt>{"comments"=>["edit", "official"], "events"=>["create_private", "create_irekia"], "news"=>["create"]}</tt>
  #
  def all_permission_by_module
    all_perms = {}
    all_permissions.each {|p| all_perms.has_key?(p.module) ? all_perms[p.module] << p.action : all_perms[p.module] = [p.action]}
    return all_perms
  end

  # Devuelve los mismos permisos que <tt>all_permissions</tt> pero en el siguiente formato,
  # adecuado para los campos del formulario
  # <tt>[perm[news][create], perm[events][create_private]]</tt>
  def permissions_for_form_array
    output = self.all_permissions.collect {|p| "perm[#{p.module}][#{p.action}]"}
    # logger.info "permissions_for_form_array #{output.inspect}"
    return output
  end

  # Actualiza los permisos del usuario, tanto los de los eventos especiales como los permisos generales
  def update_permissions(new_permissions)
    new_permissions ||= {}
    self.transaction do
      logger.info "Nuevos permisos..... #{new_permissions.inspect}"
      self.permissions.clear
      new_permissions.each do |mod, permissions|
        permissions.each do |perm|
          self.permissions.build(:module => mod, :action => perm[0]) if perm[1].to_i == 1
        end
      end
      self.save
    end
  end


  attr_writer :stream_flow_ids
  # Los RoomManagers tienen <tt>stream_flow_ids</tt> gracias a <tt>has_many :stream_flows, :through => :room_managements</tt>,
  # que son las salas de las que son responsables. Necesitamos definir para el resto de usuarios este método para vaciar
  # el mapping cuando cambiamos un usuario de RoomManager a otro role.
  def stream_flow_ids=(val)
    RoomManagement.delete_all("room_manager_id = #{self.id}") unless (self.new_record? || self.is_a?(RoomManager))
  end

  def is_outside_user?
    is_twitter_user? || is_facebook_user? || is_googleplus_user?
  end

  def is_twitter_user?
    screen_name.present?
  end

  def is_facebook_user?
    fb_id.present?
  end

  def is_googleplus_user?
    googleplus_id.present?
  end

  # irekia-auth API related methods
  def role4api
    self.type.to_s
  end

  def name4api
    self.name
  end

  def lastname4api
    self.last_names
  end

  # not used
  # def postal_code4api
  #   self.zip
  # end

  def province4api
    self.state
  end

  def city4api
    self.city
  end

  def follows?(item)
    self.send("following_#{item.class.name.downcase.pluralize}").include?(item) if item.present?
  end

  def not_follows?(item)
    !self.follows?(item)
  end

  def active_notifications_for(item)
    self.notifications.pending.where("notifiable_id=#{item.id} AND notifiable_type='#{item.class.base_class}'")
  end

  def deactivate_account
    self.status = 'eliminado'
    self.email = "deleted_#{self.id}@email.com"
    self.remove_photo!
    self.name = 'deleted'
    self.last_names = 'deleted'
    self.screen_name = nil
    self.fb_id = nil
    self.asecret = nil
    self.atoken = nil
    self.googleplus_id = nil
    pass = User.random_password
    self.password = pass
    self.password_confirmation = pass
    if self.is_a?(Journalist)
      self.media = 'deleted'
      self.last_names = 'deleted'
    end
    self.comments.map{|c| c.update_attribute(:name, 'deleted')}
    self.save
  end

  # Genera un password aleatorio
  # http://snippets.dzone.com/posts/show/2137
  def self.random_password(size = 5)
    chars = (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0 I O)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end

  def approved?
    self.status.eql?('aprobado')
  end

  def approved_and_published_proposals
    self.proposals.approved.published
  end

  # Todos los comentarios del usuario en irekia o desde el widget de comentarios.
  # NOTA: Para coger sólo los comentarios hechos en irekia, usar: self.comments.local.approved
  def approved_comments
    self.comments.approved
  end

  # toreview: only god knows why the has_many query doesn't work, it seems to query the tags table :/ 
  def comments
    Comment.where(user_id: self.id).order("created_at DESC")
  end

  def approved_arguments
    self.arguments.published
  end

  def approved_headlines
    []
  end

  # Esto lo necesito para poder aplicar el scope "leading" sobre las noticias del home de un usuario
  # porque en el home de usuario se usa la misma función que en el home de un área o de un político
  def tag_name_es
    "los usuarios no tienen tag"
  end

  # Acciones del político
  include Tools::WithActions

  def news_for_bulletin(bulletin_id)
    bulletin_featured_news = Bulletin.find(bulletin_id).featured_news_ids
    news_for_user = []
    # logger.info "AAAAAAAAA #{news_for_user.inspect}"
    if self.following_areas.present?
      self.following_areas.each do |area|
        conditions = exclusion_conditions((bulletin_featured_news + news_for_user + sent_in_previous_bulletins).uniq)
        if news_for_user.length < Bulletin::MAX_USER_NEWS
          news_for_user << (area.featured_news.where(conditions).order("published_at DESC").first || area.news.listable.where(conditions).order("published_at DESC").first).id
        end
        # logger.info "BBBBBBBBB #{news_for_user.inspect}"
      end
    end
    conditions = exclusion_conditions((bulletin_featured_news + news_for_user + sent_in_previous_bulletins).uniq)
    news_for_user += News.published.translated.listable.where(conditions).limit(Bulletin::MAX_USER_NEWS - news_for_user.length).collect(&:id)
    # logger.info "CCCCCCCCC #{bulletin_featured_news.inspect} + #{news_for_user.inspect}"
    news_for_user
  end

  def old_password_is_correct
    if old_password.present? && crypted_password != encrypt(@old_password)
      self.errors.add(:old_password, I18n.t('activerecord.errors.messages.invalid'))
    else
      true
    end
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    notification = Notifier.password_reset(self)
    email_exception { notification.deliver }
  end

  # Los usuario de este tipo no necesitan algunos de los campos de la tabla <tt>users</tt>.
  # Aquí vaciamos esos campos.
  def reset_unnecessary_fields
    self.department_id = nil
    self.media = nil
    self.stream_flow_ids = []
    self.media = nil
    self.raw_location = nil
    self.lat = nil
    self.lng = nil
    self.city = nil
    self.state = nil
    self.country_code = nil
    self.zip = nil
    self.photo_file_name = nil
    self.photo_content_type = nil
    self.photo_file_size = nil
    self.photo_updated_at = nil
    self.url = nil
    self.organization = nil
    self.public_role_es = nil
    self.public_role_eu = nil
    self.public_role_en = nil
    self.gc_id = nil
    self.description_es = nil
    self.description_eu = nil
    self.description_en = nil
    self.politician_has_agenda = nil
  end


  protected
    def exclusion_conditions(news_ids)
      conditions = news_ids.length > 0 ? "documents.id NOT IN (#{news_ids.join(',')})" : nil
    end

    def sent_in_previous_bulletins
      Bulletin.sent_featured_news + self.bulletin_copies.collect(&:news_ids).flatten
    end

    # Encripta la contraseña
    def encrypt_password
      if self.is_a?(Journalist) && self.new_record?
        generate_random_password_if_empty
      end

      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.zone.now.to_s}--#{email}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    # Por defecto los usuarios están aprobados. Se llama desde before_create.
    def set_default_status
      self.status = 'aprobado' unless self.status
    end

    # Resetea los permisos de la tabla permissions si el usuario cambia de role
    def reset_permissions_if_role_changed
      self.permissions.clear if self.type_changed?
    end

    def destroy_pending_alerts
      EventAlert.delete_all("spammable_id=#{self.id} AND sent_at IS NULL")
    end

    # Determina si el password es obligatorio
    def password_required?
      !type.eql?('Journalist') && !is_twitter_user? && !is_facebook_user? && !is_googleplus_user? && (crypted_password.blank? || !password.blank?)
    end

    # Indica si el email está vacío
    def email_blank
      self.email.blank?
    end

    # Genera un password aleatorio
    def generate_random_password_if_empty
      self.password = Journalist.random_password if self.password.blank?
    end

    # Si el usuario deja la URL con el valor por defecto, se quita porque no es
    # una URL válida
    def nullify_url_if_necessary
      self.url = nil if self.url.eql?("http://")
      return true
    end

    # Crea el tag del político. Se llama desde after_create de un político o al cambiar el tipo de usuario.
    def create_new_politician_tag
      tag = ActsAsTaggableOn::Tag.create(:name_es => self.public_name, :name_eu => self.public_name, :name_en => self.public_name, :kind => 'Político', :kind_info => self.id.to_s, :translated => true)
      tag
    end

    # Si ha cambiado el tipo del usuario y el nuevo tipo es Politician, creamos el tag
    def create_tag_if_changed_to_politician
      if !self.respond_to?('tag') && self.type_changed? && self.type.eql?('Politician')
        tag = create_new_politician_tag()
        tag.taggings.create(:taggable_type => 'User', :taggable_id => self.id, :context => 'tags')
      end
    end

    def reset_official_commenters
      if self.type_changed? || User::STAFF.include?(self.type_was)
        User.official_commenters = nil
      end
    end

    def generate_token(column)
      begin
        self[column] = SecureRandom.base64.tr("+/", "-_")
      end while User.exists?(column => self[column])
    end
  
end
