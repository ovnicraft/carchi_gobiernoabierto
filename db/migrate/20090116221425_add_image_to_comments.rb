class AddImageToComments < ActiveRecord::Migration
  def self.up
    add_column :documents, :has_comments_with_photos, :boolean, :default => false
    Document.update_all("has_comments_with_photos='f'")
  end

  def self.down
    remove_column :documents, :has_comments_with_photos
  end
end
