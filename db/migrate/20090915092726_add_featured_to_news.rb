class AddFeaturedToNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :featured, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :documents, :featured
  end
end
