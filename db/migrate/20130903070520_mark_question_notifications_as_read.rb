class MarkQuestionNotificationsAsRead < ActiveRecord::Migration
  def self.up
    notifications = Notification.joins("inner join contributions on (notifications.notifiable_id=contributions.id)".where("type='Question' and read_at is null", :readonly => false)
    notifications.each do |n|
      n.read_at = '2013-09-01'
      n.save
    end
  end

  def self.down
  end
end
