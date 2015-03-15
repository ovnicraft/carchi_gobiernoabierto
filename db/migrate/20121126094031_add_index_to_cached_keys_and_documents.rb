class AddIndexToCachedKeysAndDocuments < ActiveRecord::Migration
  def self.up
    add_index :cached_keys, [:cacheable_id, :cacheable_type]
    add_index :documents, [:id, :type]    
  end

  def self.down                           
    remove_index :documents, :column => [:id, :type]                      
    remove_index :cached_keys, :column => [:cacheable_id, :cacheable_type]
  end
end
