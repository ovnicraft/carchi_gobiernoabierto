class AddAuthorToItems < ActiveRecord::Migration
  def self.up
    add_column :documents, :created_by, :integer
    add_column :documents, :updated_by, :integer
    add_column :categories, :created_by, :integer
    add_column :categories, :updated_by, :integer
    add_column :tags, :created_by, :integer
    add_column :tags, :updated_by, :integer
    add_column :images, :created_by, :integer
    add_column :images, :updated_by, :integer
    
    Document.update_all('created_by=1, updated_by=1')
    Category.update_all('created_by=1, updated_by=1')
    Tag.update_all('created_by=1, updated_by=1')
    Image.update_all('created_by=1, updated_by=1')
  end

  def self.down
    remove_column :documents, :created_by
    remove_column :documents, :updated_by
    remove_column :categories, :created_by
    remove_column :categories, :updated_by
    remove_column :tags, :created_by
    remove_column :tags, :updated_by
    remove_column :images, :created_by
    remove_column :images, :updated_by
  end
end
