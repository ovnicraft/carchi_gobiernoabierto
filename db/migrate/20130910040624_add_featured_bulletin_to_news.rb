class AddFeaturedBulletinToNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :featured_bulletin, :boolean
  end

  def self.down
    remove_column :documents, :featured_bulletin
  end
end