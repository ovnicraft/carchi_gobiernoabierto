class CreateRelatedEvents < ActiveRecord::Migration
  def self.up
    create_table :related_events do |t|
      t.string  :eventable_type
      t.integer :eventable_id
      t.integer :event_id
      t.integer :created_by
      t.integer :updated_by      
      t.timestamps
    end
    
    execute 'ALTER TABLE related_events ADD CONSTRAINT related_event_id_fk FOREIGN KEY (event_id) REFERENCES documents(id)'
  end

  def self.down
    drop_table :related_events
  end
end
