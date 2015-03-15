# Clase para los usuarios de tipo "Administrador". Es subclase de User, 
# por lo que su tabla es <tt>users</tt>
class Admin < User

  # Permisos heredados por los usuarios de este tipo
  def self.inherited_permissions
    [{:module => "news", :action => "create"}, {:module => "news", :action => "complete"}, {:module => "news", :action => "export"},
     {:module => "comments", :action => "edit"}, {:module => "comments", :action => "official"},
     {:module => "proposals", :action => "edit"},
     {:module => "events", :action => "create_private"}, {:module => "events", :action => "create_irekia"}]
  end
  
  private
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
  
end
