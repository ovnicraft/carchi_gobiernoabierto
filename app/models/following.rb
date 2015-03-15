class Following <ActiveRecord::Base
  belongs_to :user
  belongs_to :followed, :polymorphic => true
  
  validates_presence_of :user_id, :followed_id, :followed_type  
  validates_uniqueness_of :user_id, :scope => [:followed_id, :followed_type]
end  