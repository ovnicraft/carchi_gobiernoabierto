class CreateRoomManagers < ActiveRecord::Migration
  def self.up
    create_table :room_managers do |t|
      t.string :name, :null => false
      t.string :email, :null => false
      t.string :telephone
      t.timestamps
    end
  end

  def self.down
    drop_table :room_managers
  end
end
