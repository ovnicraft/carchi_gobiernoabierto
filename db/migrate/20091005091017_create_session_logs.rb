class CreateSessionLogs < ActiveRecord::Migration
  def self.up
    create_table :session_logs do |t|
      t.integer :user_id, :null => false
      t.string :action, :null => false
      t.timestamp :action_at, :null => false
      t.string  :user_ip
      t.timestamps
    end
  end

  def self.down
    drop_table :session_logs
  end
end
