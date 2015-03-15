class CloseCommentsOnDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :comments_closed, :boolean, :default => false
    Document.update_all("comments_closed='f'")
    execute 'ALTER TABLE documents ALTER COLUMN comments_closed SET NOT NULL'
  end

  def self.down
    remove_column :documents, :comments_closed
  end
end
