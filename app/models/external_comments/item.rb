class ExternalComments::Item < ActiveRecord::Base
  self.table_name = "external_comments_items"

  belongs_to :client, :class_name => "ExternalComments::Client", :foreign_key => "client_id"
  include ActsAsCommentable

  belongs_to :irekia_news, :class_name => "News", :foreign_key => "irekia_news_id"

  validates_presence_of :client
  validates_presence_of :url

  before_save :set_title_if_empty
  after_create :save_department_and_organization_in_stats_counter

  def department
    self.client.organization.department
  end

  # Si el item corresponde a una noticia de irekia, 
  # cogemos los comentarios sobre todos los items que corresponden a esta noticia.
  # Si el item tiene asigando un content_local_id,
  # cogemos todos los comentarios sobre items con el mismo content_local_id
  # (se usa para las páginas de euskadi.net que tienen el mismo content_local_id
  # pero diferente URL porque se publican en diferentes webs.
  # Si el item no tiene asignada una noticia de irekia,
  # devolvemos sólo sus comentarios.
  #
  def all_comments
    if self.irekia_news
      all_items = self.class.where(["irekia_news_id = ?", self.irekia_news_id]).map {|item| item.id}
      Comment.external_and_irekia_for(all_items, self.irekia_news_id)
    elsif self.content_local_id.present?
      all_items = self.class.where(content_local_id: self.content_local_id).select("id").map(&:id)
      all_items.present? ? Comment.external_for(all_items) : Comment.none
    else
      self.comments
    end
  end

  # Métodos para compatibilidad con los demás modelos que tienen comentarios.

  def has_comments?
    true
  end

  def title_es
    title
  end

  def title_eu
    title
  end

  def title_en
    title
  end
  
  # Se usa tag_ids para filtrar los comentarios por departamento.
  # Los demás contenidos comentables tienen definido el método tag_ids
  # que devuelve los ids de todos sus tags. El departamento es siempre uno
  # de los tags ocultos de los contenidos así que su tag está en la tag_ids
  # Para las páginas externas, cogemos el departamento de la organización
  # a la que está asignado el cliente.
  def tag_ids
    [ActsAsTaggableOn::Tag.find_by_name_es(self.department.tag_name).id]
  end

  # Los tags de área del item son los de la noticia de irekia que le corresponde.
  # Si no tiene asignada ninguna noticia en irekia, no tiene +area_tags+.
  def area_tags
    self.irekia_news.present? ? self.irekia_news.area_tags : nil
  end

  def type
    self.class
  end

  # Fin de los métodos para compatibilidad.

  private

  def set_title_if_empty
    self.title = self.url if self.title.blank?
  end

  # Override the one defined in ActsAsCommentable
  def update_department_organization_and_area_in_stats_counters
    true
  end

  def save_department_and_organization_in_stats_counter
    counter = self.stats_counter || self.build_stats_counter
    counter.organization_id = self.client.organization_id
    counter.department_id = self.client.organization.department.id
    counter.save
  end
end
