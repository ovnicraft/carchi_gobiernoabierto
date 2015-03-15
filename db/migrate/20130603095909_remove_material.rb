class RemoveMaterial < ActiveRecord::Migration
  def self.up
    drop_table :materials
  end

  def self.down
  end
end
