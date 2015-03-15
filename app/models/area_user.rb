class AreaUser < ActiveRecord::Base
  belongs_to :area
  belongs_to :user
  
  attr_accessor :name_and_email
  after_create :set_position_if_empty
  
  private
  
  def set_position_if_empty
    self.update_attribute(:position, self.id) if self.position.to_i.eql?(0)
  end
  
end
