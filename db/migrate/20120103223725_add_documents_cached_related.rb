class AddDocumentsCachedRelated < ActiveRecord::Migration
  def self.up
    add_column :documents, :cached_related, :text
  end

  def self.down
    remove_column :documents, :cached_related
  end
end