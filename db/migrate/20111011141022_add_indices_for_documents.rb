class AddIndicesForDocuments < ActiveRecord::Migration
  def self.up
    add_index :documents, :published_at
    add_index :cached_keys, :cacheable_id
  end

  def self.down
    remove_index :cached_keys, :cacheable_id
    remove_index :documents, :published_at
  end
end