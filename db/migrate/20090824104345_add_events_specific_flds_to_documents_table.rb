class AddEventsSpecificFldsToDocumentsTable < ActiveRecord::Migration
  def self.up
    add_column :documents, :state, :string, :limit => 30
    add_column :documents, :is_private, :boolean, :default => true
    add_column :documents, :city, :string
    add_column :documents, :has_journalists, :boolean
    add_column :documents, :has_photographers, :boolean
    add_column :documents, :streaming_live, :boolean
    add_column :documents, :irekia_coverage, :boolean
  end

  def self.down
    remove_column :documents, :irekia_coverage
    remove_column :documents, :streaming_live
    remove_column :documents, :has_photographers
    remove_column :documents, :has_journalists
    remove_column :documents, :city
    remove_column :documents, :is_private
    remove_column :documents, :state
  end
end
