class AddSendAtToBulletins < ActiveRecord::Migration
  def self.up
    add_column :bulletins, :send_at, :timestamp
  end

  def self.down
    remove_column :bulletins, :send_at
  end
end
