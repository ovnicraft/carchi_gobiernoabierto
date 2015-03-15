class AddAltToCoverPhoto < ActiveRecord::Migration
  def self.up
    add_column :documents, :cover_photo_alt, :string
  end

  def self.down
    remove_column :documents, :cover_photo_alt
  end
end
