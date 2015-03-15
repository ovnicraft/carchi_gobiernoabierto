class AddActiveToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :active, :boolean, :default => true, :null => false
    execute "UPDATE organizations SET active='t'"
  end

  def self.down
    remove_column :organizations, :active
  end
end