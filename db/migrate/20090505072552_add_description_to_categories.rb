class AddDescriptionToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :description_es, :text
    add_column :categories, :description_eu, :text
    add_column :categories, :description_en, :text
  end

  def self.down
    remove_column :categories, :description_en
    remove_column :categories, :description_eu
    remove_column :categories, :description_es
  end
end
