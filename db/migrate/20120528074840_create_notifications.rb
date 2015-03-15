class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.integer :item_id
      t.string :item_type
      t.string :action
      t.integer :counter
      t.datetime :read_at
      t.references :user
      t.timestamps
    end
    execute 'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(id)'
  end

  def self.down
    drop_table :notifications
  end
end
