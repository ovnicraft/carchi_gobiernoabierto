class ChangeNotifications < ActiveRecord::Migration
  def self.up
    rename_column :notifications, :item_id, :notifiable_id
    rename_column :notifications, :item_type, :notifiable_type
    Notification.update_all("notifiable_type='Contribution'")
  end

  def self.down
    rename_column :notifications, :notifiable_type, :item_type
    rename_column :notifications, :notifiable_id, :item_id
  end
end