class AddTypeColumnToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :type, :string
    add_index :documents, :type
    Document.update_all("type='News'")
    execute 'ALTER TABLE documents ALTER COLUMN type SET NOT NULL'
    execute "ALTER TABLE documents ALTER COLUMN type SET DEFAULT 'News'"
  end

  def self.down
    remove_index :documents, :type
    remove_column :documents, :type
  end
end
