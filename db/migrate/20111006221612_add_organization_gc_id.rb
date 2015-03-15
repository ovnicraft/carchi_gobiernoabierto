class AddOrganizationGcId < ActiveRecord::Migration
  def self.up
    add_column :organizations, :gc_id, :integer
  end

  def self.down
    remove_column :organizations, :gc_id
  end
end