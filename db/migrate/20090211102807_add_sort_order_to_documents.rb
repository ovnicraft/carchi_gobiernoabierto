class AddSortOrderToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :position, :integer, :default => 100
    Document.update_all("position=100")
    execute 'ALTER TABLE documents ALTER COLUMN position SET NOT NULL'
  end

  def self.down
    remove_column :documents, :position
  end
end
