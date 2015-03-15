class SetDefaultValueForIrekiaCoverageInEvents < ActiveRecord::Migration
  def self.up
    change_column :documents, :irekia_coverage, :boolean, :null => false, :default => false
    change_column :documents, :streaming_live, :boolean, :null => false, :default => false
  end

  def self.down
    change_column :documents, :irekia_coverage, :boolean
    change_column :documents, :streaming_live, :boolean
  end
end