class AddEnglishColumns < ActiveRecord::Migration
  def self.up
    add_column :documents, :title_en, :string
    add_column :documents, :body_en, :text
    add_column :categories, :name_en, :string
    add_column :trees, :name_en, :string
  end

  def self.down
    remove_column :trees, :name_en
    remove_column :categories, :name_en
    remove_column :documents, :body_en
    remove_column :documents, :title_en
  end
end
