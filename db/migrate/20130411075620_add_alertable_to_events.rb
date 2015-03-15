class AddAlertableToEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :alertable, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :documents, :alertable
  end
end