class AddEventAlertNotifyAbout < ActiveRecord::Migration
  def self.up
    add_column :event_alerts, :notify_about, :string, :limit => 30
  end

  def self.down
    remove_column :event_alerts, :notify_about
  end
end
