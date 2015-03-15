class AddPublishedAtToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :published_at, :datetime
    Document.update_all("published_at='#{Time.zone.now.strftime('%Y-%m-%d %H%M')}'")
  end

  def self.down
    remove_column :documents, :published_at
  end
end
