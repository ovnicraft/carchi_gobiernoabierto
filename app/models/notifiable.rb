module Notifiable
  
  def self.included(base)
    base.after_save :update_notifications
  end
  
  def update_notifications
    item = get_item
    if self.approved? && item
      users_to_notify = [item.user_id]
      users_to_notify.each do |user_id|
        params = {:notifiable_id => item.id, :notifiable_type => item.class.base_class.to_s, :action => self.class.to_s.downcase, :user_id => user_id, :read_at => nil}
        if Notification.exists?(params)
          notification = Notification.where(params).first
          notification.counter = notification.counter + 1
          notification.save!
        else
          Notification.create(params.merge({:counter => 1}))
        end
      end
    end
  end
  
  def get_item
    case self.class.name
    when "Comment"
      item = self.get_commentable 
    when "Argument"
      item = self.argumentable
    when "Vote"
      item = self.votable
    end
    item = nil unless (item.is_a?(Proposal) && item.approved? && item.published?)
    return item
  end
  
end
