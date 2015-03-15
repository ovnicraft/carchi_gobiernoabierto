class ChangeNewsFeaturedField < ActiveRecord::Migration
  def self.up
    remove_column :documents, :featured
    add_column :documents, :featured, :string, :limit => 5
  end

  def self.down
    remove_column :documents, :featured
    add_column :documents, :featured, :boolean,                           :default => false
  end
end
