class AddGeoLocFieldsForAgenda < ActiveRecord::Migration
  def self.up
    add_column :documents, :speaker, :string
    add_column :documents, :lat, :numeric
    add_column :documents, :lng, :numeric
    add_column :documents, :location_for_gmaps, :string, :limit => 500
  end

  def self.down
    remove_column :documents, :location_for_gmaps
    remove_column :documents, :speaker
    remove_column :documents, :lat
    remove_column :documents, :lng
  end
end
