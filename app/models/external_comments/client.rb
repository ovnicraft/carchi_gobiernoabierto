# Clientes para el widget de comentarios
class ExternalComments::Client < ActiveRecord::Base
  self.table_name = "external_comments_clients"
  
  belongs_to :organization
  has_many :commentable_items, :class_name => "ExternalComments::Item", :foreign_key => "client_id"
  
  validates_presence_of :name, :url, :code, :organization_id
  validates_length_of :url, :maximum => 255, :allow_blank => true
  validates_length_of :name, :maximum => 255, :allow_blank => true  
  validates_length_of :code, :maximum => 255, :allow_blank => true    
  
  validates_uniqueness_of :code
  
  before_validation :set_organization_id_if_nil
  before_save :clear_url
  after_save :update_stat_counters_organization
  
  def organization_name
    self.organization.present? ? self.organization.name : '-'
  end
  
  
  private
  
  def clear_url
    self.url = self.url.gsub(/^http.\/\//,'').gsub(/\/\s*$/,'')
  end
  
  def set_organization_id_if_nil
    if self.new_record? && self.organization_id.blank?
      self.organization_id = default_organization.id if default_organization
    end
    true
  end
  
  # El cliente tiene que tener asignado un departamento. Por defecto, cualquiera, luego se puede cambiar
  def default_organization
    Department.order("id").first
  end
  
  def update_stat_counters_organization
    if self.organization_id_changed? 
      self.commentable_items.all.each do |item|
        if item.stats_counter
          item.stats_counter.update_attributes(:organization_id => self.organization_id, :department_id => self.organization.department.id)
        end
      end
    end
  end
end
