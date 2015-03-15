class Sorganization <ActiveRecord::Base
  has_many :snetworks, -> { order("position") }, :dependent => :destroy
  belongs_to :department
  
  has_attached_file :icon, :styles => {:tiny => "39x39#"},
                    :url  => "/uploads/sorganizations/:id/:style/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/sorganizations/:id/:style/:sanitized_basename.:extension"
  
  translates :name
  
  validates_presence_of :name
  do_not_validate_attachment_file_type :icon
  validate :icon_size_valid?
  validates_associated :snetworks
  
  after_update :save_snetworks
  
  def icon_size_valid?
    begin
      # El tamaño del icono debe ser 39x37
      unless self.icon.tempfile.nil?
        size=Paperclip::Geometry.from_file(self.icon.tempfile.path)
        if size.width.to_i != 39 || size.height.to_i != 39
          self.errors.add(:icon, 'debe tener un tamaño de 39x39px')
          false
        end
      end
    rescue NotIdentifiedByImageMagickError, NoMethodError => err
      logger.error "Error checking icon size: #{err}"
    end
  end

  def new_snetworks_attributes=(values)
    values.each_pair do |key, snet|
      self.snetworks.build(snet)
    end  
  end
  
  def existing_snetworks_attributes=(values)
    self.snetworks.reject(&:new_record?).each do |snet|      
      attributes=values[snet.id.to_s]
      if attributes['deleted'].to_i == 1
        snetworks.delete(snet)
      else
        snet.attributes=attributes  
      end  
    end  
  end
  
  def save_snetworks
    snetworks.each do |snetwork|
      snetwork.save
    end
  end
  
end
