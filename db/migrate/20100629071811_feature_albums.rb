class FeatureAlbums < ActiveRecord::Migration
  def self.up
    add_column :albums, :featured, :boolean, :default => false
    add_column :albums, :album_photos_count, :integer, :default => 0
    
    Album.reset_column_information  
    Album.all.each do |a|  
      a.album_photos_count=a.album_photos.count
      a.save
    end
  end

  def self.down
    remove_column :albums, :album_photos_count
    remove_column :albums, :featured
  end
end
