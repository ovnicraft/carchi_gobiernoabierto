class EventLocation < ActiveRecord::Base
  validates_presence_of :city, :place, :address, :lat, :lng

  # Nombre del sitio
  def name
    self.place
  end
  
  # Coordenadas del sitio
  def coord
    [self.lat, self.lng]
  end
  
  # Para compatibilidad con Event
  def pretty_place
    full_info = [self.place, self.city].map {|e| e.blank? ? nil : e }.compact
    full_info.empty? ? "" : full_info.join(", ")
  end
  
  # Para compatibilidad con Event
  def location_for_gmaps
    self.address
  end
  
end
