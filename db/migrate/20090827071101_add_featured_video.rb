class AddFeaturedVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :featured, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :videos, :featured
  end
end
