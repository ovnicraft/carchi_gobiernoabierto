# Clase para los usuarios de tipo "Miembro de departamento". Es subclase de User, por lo que su
# tabla es <tt>users</tt>
class DepartmentMember < User
  belongs_to :department
  
  # Indica si tiene permiso para acceder a la administración de los recursos de tipo <tt>doc_type</tt>.
  # Ejemplos:
  # - current_user.can_access?("news")
  # - current_user.can_access?("photos")
  def can_access?(doc_type)
    ["events"].include?(doc_type)
  end
  
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
      false
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
      false
    end
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
