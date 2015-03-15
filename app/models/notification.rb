class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notifiable, :polymorphic => true
  validates_uniqueness_of :user_id, :scope => [:notifiable_id, :notifiable_type, :action, :read_at]
  scope :pending, -> { where("read_at IS NULL") }

  def mark_as_read!
    self.read_at = Time.zone.now
    self.save!
  end
end
