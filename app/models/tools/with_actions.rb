#
# Métodos comunes para los contenidos que tie nen acciones: áreas y políticos.
# Las instancias del modelo que incuye este módulo tienen que tener definido el método tag_name_es
#
module Tools::WithActions
  # Noticias que comparten tags con el modelo
  def news
    News.published.translated.tagged_with(self.tag_name_es)
  end
  
  def news_count
    self.news.count('distinct documents.id')
  end
  
  def featured_news
    News.published.translated.tagged_with(self.featured_tag_name_es)
  end
  
  # Eventos del área: son los eventos que comparten tags con el área
  def events
    Event.published.translated.tagged_with(self.tag_name_es)
  end
  
  def events_count
    self.events.count('distinct documents.id')
  end

  # Vídeos del área: son los vídeos que tienen el tag del área
  def videos
    Video.published.translated.tagged_with(self.tag_name_es).uniq
  end
  
  def videos_count
    self.videos.count('distinct videos.id')
  end
  
  # Álbumes de un área: son los álbumes que tienen el tag del área
  def albums
    Album.published.with_photos.tagged_with(self.tag_name_es).uniq
  end
  
  def albums_count
    self.albums.count('distinct albums.id')
  end
  
  # Fotos de un área: son las fotos que tienen el tag del área
  def photos
    Photo.published.tagged_with(self.tag_name_es).uniq
  end  
  
  def photos_count
    self.photos.count('distinct photos.id')
  end

  # Propuestas del área: son las propuestas que comparten tags con el área
  def approved_and_published_proposals
    Proposal.approved.published.tagged_with(self.tag_name_es) #translated???
  end

  def published_debates
    Debate.published.translated.tagged_with(self.tag_name_es)
  end
  
  def proposals_count
    self.approved_and_published_proposals.count('distinct proposals.id')
  end

  def debates
    Debate.tagged_with(self.tag_name_es)
  end

  def debates_count
    self.published_debates.count('distinct debates.id')
  end
  
  def comments
    Comment.approved.tagged_with(self.tag_name_es)
  end
  
  def answers
    Comment.official.approved.tagged_with(self.tag_name_es)
  end
  
  # Los métodos sobre preguntas y respuestas son diferentes para áreas y políticos y se definen en cada modelo.  
end
