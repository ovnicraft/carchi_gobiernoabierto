class AddMultimediaContentPathsToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :video_path, :string
    add_column :documents, :audio_path, :string
  end

  def self.down
    remove_column :documents, :video_path
    remove_column :documents, :audio_path
  end
end
