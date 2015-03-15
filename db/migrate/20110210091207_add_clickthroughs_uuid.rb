class AddClickthroughsUuid < ActiveRecord::Migration
  def self.up
    add_column :clickthroughs, :uuid, :string
  end

  def self.down
    remove_column :clickthroughs, :uuid
  end
end