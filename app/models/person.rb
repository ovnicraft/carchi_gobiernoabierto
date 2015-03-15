# Clase para los usuarios de tipo "persona", los usuarios que se registran en Irekia para comentar. 
# Es subclase de User, por lo que su tabla es <tt>users</tt>
class Person < User
  validates_length_of :name, :maximum => 255
  validates_length_of :last_names, :raw_location, :maximum => 255, :allow_blank => true
  validates_acceptance_of :normas_de_uso, :on => :create
  
  validates_presence_of :screen_name, :if => :is_twitter_user?
  
  include Geokit::Geocoders
  attr_accessor :normas_de_uso
  
  scope :approved, -> { where("users.status='aprobado'")}
  scope :pending, -> {where("users.status='pendiente'")}
  
  # Devuelve la ciudad en la que vive.
  def public_city
    (raw_location.present? && raw_location.strip.match(/\d+/)) ? city : raw_location
  end
  
  before_create :set_pending_status
  before_save :fill_lat_lng_data
  
  # Indica si el usuario puede crear contenidos de tipo <tt>doc_type</tt>
  # Los tipos de contenido disponibles se pueden consultar en #Permission
  def can_create?(doc_type)
    doc_type.eql?("comments")
  end
  
  protected
  
  # Las personas quedan en estado de "pendientes de aprobación" cuando se dan de alta.
  # Se llama desde before_create
  def set_pending_status
    self.status = "pendiente" unless (is_twitter_user? || is_facebook_user? || is_googleplus_user?)
  end
  
  # Coge de Google las coordenadas geográficas, ciudad, etc de la persona y las guarda.
  # Se llama desde before_save
  def fill_lat_lng_data
    if raw_location_changed?
      loc = GoogleV3Geocoder.geocode("#{raw_location}, Spain")
      unless loc.success
        loc = GoogleV3Geocoder.geocode(raw_location)
      end
    
      if loc.success
        self.lat, self.lng = slightly_modify_location(loc.lat, loc.lng)
        self.city = loc.city
        self.zip = loc.zip
        self.state = loc.state
        self.country_code = loc.country_code
      end
    end
  end
  
  # Vacia los campos irrelevantes para este tipo de usuario.
  # Se llama desde before_save
  def reset_unnecessary_fields
    self.department_id = nil
    self.media = nil
    self.telephone = nil
    self.organization = nil
    self.stream_flow_ids = []
    self.public_role_es = nil
    self.public_role_eu = nil
    self.public_role_en = nil
    self.gc_id = nil
    self.description_es = nil
    self.description_eu = nil
    self.description_en = nil
    self.politician_has_agenda = nil
  end
  
  # Modifica ligeramente la posición que devuelve Google Maps para la localidad de este usuario 
  # para que los pinchos no aparezcan todos unos encima de otros.
  def slightly_modify_location(lat, lng)
    deviation = 0.0060
    
    lat_rand = rand * deviation
    lng_rand = rand * deviation

    lat_sign = rand < 0.5 ? -1 : 1
    lng_sign = rand < 0.5 ? -1 : 1
    
    new_lat = lat + (lat_sign * lat_rand)
    new_lng = lng + (lng_sign * lng_rand)
    
    return [new_lat, new_lng]
  end
  
end
