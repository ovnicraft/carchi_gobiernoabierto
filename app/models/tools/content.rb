# Métodos compartidos entre todas las clases que salen en las listas de acciones en la parte pública
module Tools::Content

  # Idiomas disponibles
  LANGUAGES = [:es, :eu, :en]

  def last_comments
    self.comments.limit(2)
  end
  
  #
  # Para compatibilidad con los demás contenidos principales.
  #
  def moderated?
    false
  end
  
end