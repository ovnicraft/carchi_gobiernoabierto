class RelatedEvent < ActiveRecord::Base
  belongs_to :event, :class_name => "Event", :foreign_key => "event_id"
  belongs_to :eventable, :polymorphic => true
  
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_editor, :class_name => "User", :foreign_key => "updated_by"
  
  def eventable_type=(sType)
     super(sType.to_s.classify.constantize.base_class.to_s)
  end
end
