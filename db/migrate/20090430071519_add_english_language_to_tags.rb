class AddEnglishLanguageToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :name_en, :string
    add_column :tags, :sanitized_name_en, :string
    
    Tag.all.each do |tag|
      tag.name_en = tag.name_es
      tag.sanitized_name_en = tag.sanitized_name_es
      tag.save
    end
    
    execute 'ALTER TABLE tags ALTER COLUMN name_en SET NOT NULL'
    execute 'ALTER TABLE tags ALTER COLUMN sanitized_name_en SET NOT NULL'
  end

  def self.down
    remove_column :tags, :sanitized_name_en
    remove_column :tags, :name_en
  end
end
