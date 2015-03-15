class ExternalColaborator < User
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