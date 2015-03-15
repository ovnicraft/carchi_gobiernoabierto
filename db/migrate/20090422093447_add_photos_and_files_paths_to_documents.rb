class AddPhotosAndFilesPathsToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :photos_path, :string
    add_column :documents, :files_path, :string
  end

  def self.down
    remove_column :documents, :photos_path
    remove_column :documents, :files_path
  end
end
