class AddLanguagesToAlt < ActiveRecord::Migration
  def self.up
    rename_column :documents, :cover_photo_alt, :cover_photo_alt_es
    add_column :documents, :cover_photo_alt_eu, :string
    add_column :documents, :cover_photo_alt_en, :string
  end

  def self.down
    remove_column :documents, :cover_photo_alt_en
    remove_column :documents, :cover_photo_alt_eu
    rename_column :documents, :cover_photo_alt_es, :cover_photo_alt
  end
end
