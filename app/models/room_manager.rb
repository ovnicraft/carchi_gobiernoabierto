# Clase para los responsables de las salas de streaming.
# Son usuarios que no acceden a al web, sólo reciben avisos por email de streamings de su sala
class RoomManager < User
  has_many :room_managements, :dependent => :destroy
  has_many :stream_flows, :through => :room_managements
  has_many :event_alerts, :as => :spammable

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
     self.photo_file_name = nil
     self.photo_content_type = nil
     self.photo_file_size = nil
     self.photo_updated_at = nil
     self.url = nil
     self.media = nil
     self.organization = nil
     self.department_id = nil
     self.public_role_es = nil
     self.public_role_eu = nil
     self.public_role_en = nil
     self.gc_id = nil
     self.description_es = nil
     self.description_eu = nil
     self.description_en = nil
     self.politician_has_agenda = nil
  end
  
end
