# Entidades relacionadas para un debate
class DebateEntity < ActiveRecord::Base
  translates :url
  belongs_to :debate
  belongs_to :organization, :class_name => "OutsideOrganization", :foreign_key => "organization_id"
  
  validates_presence_of :organization_name, :debate_id
  validates_format_of :url_es, :url_eu, :url_en, :allow_blank => true, 
                      :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix , 
                      :message => 'no es correcta'

  attr_accessor :organization_name
  
  before_create :set_position

  
  # Si el nombre idicado corresponde a una organización que ya existe, la asignamos.
  # Si no hay ninguna organización con este nombre, la creamos.
  def organization_name=(val)
    if org = OutsideOrganization.find_by_name_es(val)
      self.organization = org
    else
      self.build_organization(:name_es => val)
    end
    
    @organization_name = val
  end
  
  def organization_name
    @organization_name ||= self.organization.present? ? self.organization.name : nil
  end
  
  private
  
  def set_position
    self.position = (self.debate.debate_entities.last.position + 1) if self.debate.entities.present?
    true
  end
  
end
