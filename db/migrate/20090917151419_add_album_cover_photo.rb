class AddAlbumCoverPhoto < ActiveRecord::Migration
  def self.up
    add_column :album_photos, :cover_photo, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :album_photos, :cover_photo
  end
end
