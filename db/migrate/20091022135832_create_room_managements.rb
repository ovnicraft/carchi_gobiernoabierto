class CreateRoomManagements < ActiveRecord::Migration
  def self.up
    create_table :room_managements do |t|
      t.integer :streaming_id
      t.integer :room_manager_id

      t.timestamps
    end
  end

  def self.down
    drop_table :room_managements
  end
end
