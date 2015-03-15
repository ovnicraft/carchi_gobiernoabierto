class OutsideOrganization < ActiveRecord::Base
  
  has_many :debate_entities, :class_name => "DebateEntity", :foreign_key => "organization_id"
  has_many :debates, :through => :debate_entities
  
  validates_presence_of :name_es
  translates :name

  mount_uploader :logo, OutsideOrganizationLogoUploader
  
  validate :logo_is_70x70, :if => Proc.new {|o| o.logo? }
  
  LOGO_DIMENSIONS = "70x70"
  
  def logo_is_70x70
    image = MiniMagick::Image.open(logo.current_path)
    unless "#{image[:width]}x#{image[:height]}".eql?(LOGO_DIMENSIONS)
      errors.add :logo, "tiene que ser #{LOGO_DIMENSIONS}" 
    end
  end
  
end
