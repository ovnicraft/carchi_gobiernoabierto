class AddTypesOfIrekiaCoverage < ActiveRecord::Migration
  def self.up
    add_column :documents, :irekia_coverage_photo, :boolean, :default => false
    add_column :documents, :irekia_coverage_video, :boolean, :default => false
    add_column :documents, :irekia_coverage_audio, :boolean, :default => false
  end

  def self.down
    remove_column :documents, :irekia_coverage_photo
    remove_column :documents, :irekia_coverage_video
    remove_column :documents, :irekia_coverage_audio
  end
end
