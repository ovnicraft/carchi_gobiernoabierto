# Clase para los usuarios de tipo "Periodista". Es subclase de User, por lo que su
# tabla es <tt>users</tt>
class Journalist < User
  validates_presence_of :last_names, :media# , :department_ids
  validates_associated :subscriptions
  validates_acceptance_of :normas_de_uso, :on => :create

  attr_accessor :normas_de_uso

  has_many :subscriptions, :class_name => "Subscription", :foreign_key => "user_id", :dependent => :destroy
  has_many :departments, -> { order("organizations.id") }, :through => :subscriptions
  accepts_nested_attributes_for :subscriptions, :allow_destroy => true
  has_many :event_alerts, :as => :spammable

  before_create :set_pending_status
  before_create :enable_event_alerts
  after_save :delete_pending_alerts_for_old_departments
  after_create :save_departments
  after_update :send_welcome_email

  def delete_pending_alerts_for_old_departments
    EventAlert.unsent.where("spammable_id=#{self.id} AND spammable_type='Journalist'").each do |alert|
        alert.destroy unless self.department_ids.include?(alert.event.department.id)
      end
  end

  # Devuelve un array con los departamentos y organismos a los que está suscrito
  def organization_ids
    o_ids = []
    self.departments.each do |dept|
      o_ids = o_ids + [dept.id]+dept.organization_ids
    end
    o_ids
  end

  # Indica si el usuario puede crear contenidos de tipo <tt>doc_type</tt>
  # Los tipos de contenido disponibles se pueden consultar en #Permission
  def can_create?(doc_type)
    doc_type.eql?("comments")
  end

  def save_departments
    self.subscriptions.each {|s| s.save}
  end


  protected
    # Vacia los campos irrelevantes para este tipo de usuario.
    # Se llama desde before_save
    def reset_unnecessary_fields
      self.department_id = nil
      self.stream_flow_ids = []
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
      self.public_role_es = nil
      self.public_role_eu = nil
      self.public_role_en = nil
      self.gc_id = nil
      self.description_es = nil
      self.description_eu = nil
      self.description_en = nil
      self.politician_has_agenda = nil
    end

    # Los periodistas quedan en estado de "pendientes de aprobación" cuando se dan de alta.
    # Se llama desde before_create
    def set_pending_status
      self.status = "pendiente"
    end

    def enable_event_alerts
      self.alerts_locale = I18n.locale if  self.alerts_locale.nil?
    end

    def send_welcome_email
      if self.status_was.eql?("pendiente") && self.status.eql?("aprobado")
        notification = Notifier.welcome_journalist(self)
        email_exception { notification.deliver }
      end
    end

end
