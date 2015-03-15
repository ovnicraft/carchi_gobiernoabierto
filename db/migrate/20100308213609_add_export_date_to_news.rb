class AddExportDateToNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :exported_to_enet_at, :datetime
  end

  def self.down
    remove_column :documents, :exported_to_enet_at
  end
end
