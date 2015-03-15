# Clase para organismos a los que pertenecen los Event
class Organization < ActiveRecord::Base
  has_many :events
  has_many :pages, :dependent => :nullify
  belongs_to :parent, :class_name => "Organization", :foreign_key => "parent_id"

  translates :name

  validates_presence_of :name_es
  validates_uniqueness_of :name_es

  acts_as_tree :order => :position
  acts_as_list :scope => :parent

  before_save :set_type
  after_update :reindex_related_documents

  scope :active, -> { where(active: true) }

  # Si es departamento, devuelve el mismo, si es organizacion, devuelve su parent
  def department
    if self.is_a?(Department)
      self
    elsif self.is_a?(Entity)
      self.parent
    end
  end

  # Enlace a la página de la organización en la guía de comunicación
  def gc_link
    if self.gc_id.present? && Rails.configuration.external_urls[:guia_uri]
      Rails.configuration.external_urls[:guia_uri] + "/#{I18n.locale}/entities/#{self.gc_id}"
    else
      nil
    end
  end

  protected

    # Clasifica el organismo como Departament o Entity en funcion de si es
    # de primer nivel o de segundo
    def set_type
      if self.parent_id == nil
        self.type = "Department"
      else
        self.type = "Entity"
      end
    end

    def reindex_related_documents
      if name_es_changed? || name_eu_changed? || name_en_changed?
        i=0
        all_doc = Document.where({:organization_id => self.id})
        while i < all_doc.length do
          Document.where(:organization_id => self.id).limit(100).offset(i).each do |doc|
            doc.update_elasticsearch_server if doc.respond_to?(:update_elasticsearch_server)
          end
          i += 100
        end
      end
    end

end
