class Clickthrough < ActiveRecord::Base
  validates_presence_of :click_source_type, :click_source_id, :locale
  belongs_to :click_source, :polymorphic => true
  belongs_to :click_target, :polymorphic => true

  validate :valid_clickthrough
  def valid_clickthrough
    if (self.click_source_id.blank? || (self.click_target_id.present? && (self.click_target_type.blank? || !self.click_target_type.classify.constantize.base_class.find(self.click_target_id))))
      errors.add(:base, "La información del clickthrough no es correcta")
    end
  end
  
  scope :to_content, ->(content) { where(:click_target_type => content.class.base_class.to_s, :click_target_id => content.id) }
end
