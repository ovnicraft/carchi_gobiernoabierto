class AddPositionToSnetworks < ActiveRecord::Migration
  def self.up
    add_column :snetworks, :position, :integer
  end

  def self.down
    remove_column :snetworks, :position
  end
end
