class RemoveIcons < ActiveRecord::Migration
  def self.up
    remove_column :organizations, :icon_id
    remove_column :documents, :icon_id
    drop_table :icons
  end

  def self.down
    add_column :organizations, :icon_id, :integer
    add_column :documents, :icon_id, :integer
  end
end
