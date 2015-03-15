# Clase para los usuarios de tipo "Jefe de prensa". Es subclase de User, por lo que su
# tabla es <tt>users</tt>
class DepartmentEditor < User
  belongs_to :department
  
  # Indica si tiene permiso para acceder a la administración de los recursos de tipo <tt>doc_type</tt>.
  # Ejemplos:
  # - current_user.can_access?("news")
  # - current_user.can_access?("photos")
  def can_access?(doc_type)
    ["news", "events", "comments", "proposals"].include?(doc_type)
  end
  
  # Indica si puede modificar recursos de tipo <tt>doc_type</tt>.
  # Ejemplos:
  # - current_user.can_edit?("news")
  # - current_user.can_edit?("photos")
  def can_edit?(doc_type)
    self.can_access?(doc_type)
  end

  # Indica si puede crear recursos de tipo <tt>doc_type</tt>.
  # Ejemplos:
  # - current_user.can_create?("news")
  # - current_user.can_create?("photos")
  def can_create?(doc_type)
    self.can_access?(doc_type)
  end  
  
  # Devuelve los permisos heredados por el usuario por su role de "Jefe de departamento"
  def self.inherited_permissions
    [{:module => "news", :action => "create"}, 
     {:module => "comments", :action => "edit"}, {:module => "comments", :action => "official"}, 
     {:module => "proposals", :action => "edit"},
     {:module => "events", :action => "create_private"}, {:module => "events", :action => "create_irekia"}]
  end
  
  protected
    # Vacia los campos irrelevantes para este tipo de usuario.
    # Se llama desde before_save
    def reset_unnecessary_fields
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
  
  
end
