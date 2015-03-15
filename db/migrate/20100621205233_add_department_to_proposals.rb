class AddDepartmentToProposals < ActiveRecord::Migration
  def self.up
    add_column :proposals, :organization_id, :integer
    add_column :proposals, :featured, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :proposals, :featured
    remove_column :proposals, :organization_id
  end
end
