class CreateEventAlerts < ActiveRecord::Migration
  def self.up
    create_table :event_alerts do |t|
      t.integer :event_id, :null => false
      t.integer :user_id, :null => false
      t.timestamp :sent_at
      t.timestamps
    end
    
    execute 'ALTER TABLE event_alerts ADD CONSTRAINT fk_ea_event_id FOREIGN KEY (event_id) REFERENCES documents(id)'
    execute 'ALTER TABLE event_alerts ADD CONSTRAINT fk_ea_user_id FOREIGN KEY (user_id) REFERENCES users(id)'
    
    add_column :users, :has_event_alerts, :boolean, :null => false, :default => false
    add_column :users, :alerts_locale, :string, :limit => "2", :default => "es", :null => false
  end

  def self.down
    remove_column :users, :has_event_alerts
    remove_column :users, :alerts_locale
    remove_index :event_alerts, :column => [:event_id, :user_id]
    drop_table :event_alerts
  end
end
