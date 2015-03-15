class AddTranslatedColumnToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :translated, :boolean, :default => false
    Tag.update_all("translated='t'", "name_es <> name_eu AND name_es <> name_en")
  end

  def self.down
    remove_column :tags, :translated
  end
end
