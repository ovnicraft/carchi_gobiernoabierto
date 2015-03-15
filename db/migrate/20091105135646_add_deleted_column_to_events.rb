class AddDeletedColumnToEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :deleted, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :documents, :deleted
  end
end
