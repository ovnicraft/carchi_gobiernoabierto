class AddIptcDataToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :date_time_original, :datetime
    add_column :photos, :date_time_digitalized, :datetime
    add_column :photos, :exif_image_width, :integer
    add_column :photos, :exif_image_length, :integer
    add_column :photos, :city, :string
    add_column :photos, :province_state, :string
    add_column :photos, :country, :string
  end

  def self.down
    remove_column :photos, :country
    remove_column :photos, :province_state
    remove_column :photos, :city
    remove_column :photos, :exif_image_length
    remove_column :photos, :exif_image_width
    remove_column :photos, :date_time_digitalized
    remove_column :photos, :date_time_original
  end
end
