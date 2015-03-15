# Clase para los usuarios de tipo "colaborador". Es subclase de User, por lo que su
# tabla es <tt>users</tt>.
#
# Muchos métodos de esta clase se definen en #User. Aquí se sobreescriben los que sea necesario
# por diferente comportamiento con aquél
class Colaborator < User  
  # Indica si tiene permiso para acceder a la administración de los recursos de tipo <tt>doc_type</tt>.
  # ==== Ejemplos:
  # - current_user.can_access?("news")
  # - current_user.can_access?("photos")
  def can_access?(doc_type)
    ["news", "photos", "videos", "stream_flows"].include?(doc_type)
  end
  
  # Indica si puede modificar recursos de tipo <tt>doc_type</tt>.
  # ==== Ejemplos:
  # - current_user.can_edit?("news")
  # - current_user.can_edit?("photos")
  def can_edit?(doc_type)
    self.can_access?(doc_type)
  end

  # Indica si puede crear recursos de tipo <tt>doc_type</tt>.
  # ==== Ejemplos:
  # - current_user.can_create?("news")
  # - current_user.can_create?("photos")
  def can_create?(doc_type)
    self.can_access?(doc_type) || doc_type.eql?("comments")
  end

  # Indica si el colaborador tiene permiso de tipo <tt>perm_type</tt> en los contenidos de tipo <tt>doc_type</tt>.
  # Los tipos de contenidos y los correspondientes permisos se pueden consultar en #Permission
  # ==== Ejemplos:
  # - current_user.can?("create", "news")
  # - current_user.can?("administer", "permissions")
  def can?(perm_type, doc_type)
    (perm_type.eql?("complete") && doc_type.eql?("news")) || permission?(perm_type, doc_type)
  end

  # Permisos atribuidos al usuario por el role "Colaborador"
  def self.inherited_permissions
    [{:module => "news", :action => "create"}, {:module => "news", :action => "complete"}]
  end
  
  protected
    # Vacia los campos irrelevantes para este tipo de usuario
    # Se llama desde before_save
    def reset_unnecessary_fields
      self.department_id = nil
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
