class AddAlertVersionToEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :journalist_alert_version, :integer, :null => false, :default => 0
    add_column :documents, :staff_alert_version, :integer, :null => false, :default => 0
    
    add_column :event_alerts, :version, :integer, :null => false, :default => 0
    add_column :event_alerts, :spammable_type, :string, :null => false
    add_column :event_alerts, :send_at, :timestamp
    rename_column :event_alerts, :user_id, :spammable_id
    
    execute "ALTER TABLE event_alerts DROP CONSTRAINT fk_ea_user_id"
  end

  def self.down
    remove_column :event_alerts, :send_at
    EventAlert.delete_all
    rename_column :event_alerts, :spammable_id, :user_id
    remove_column :event_alerts, :spammable_type
    remove_column :event_alerts, :version
    remove_column :documents, :staff_alert_version
    remove_column :documents, :journalist_alert_version
  end
end
