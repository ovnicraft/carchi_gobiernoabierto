class CreateAlbumPhotos < ActiveRecord::Migration
  def self.up
    create_table :album_photos do |t|
      t.integer :photo_id
      t.integer :album_id
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
    
    execute 'ALTER TABLE album_photos ADD CONSTRAINT fk_ap_photo_id FOREIGN KEY (photo_id) REFERENCES photos(id)'
    execute 'ALTER TABLE album_photos ADD CONSTRAINT fk_ap_album_id FOREIGN KEY (album_id) REFERENCES albums(id)'
    
  end

  def self.down
    drop_table :album_photos
  end
end
