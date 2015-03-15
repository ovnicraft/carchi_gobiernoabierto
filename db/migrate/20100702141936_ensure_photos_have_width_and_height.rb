class EnsurePhotosHaveWidthAndHeight < ActiveRecord::Migration
  def self.up
    rename_column :photos, :exif_image_width, :width  
    add_column :photos, :height, :integer
    Photo.all.each do |photo|
      photo.width, photo.height = photo.geometry_from_file if photo.width.blank?
      photo.save
    end
  end

  def self.down
    remove_column :photos, :height
    rename_column :photos, :width, :exif_image_width
  end
end
