class AddOrganizationTerm < ActiveRecord::Migration
  def self.up
    add_column :organizations, :term, :string, :limit => 10
    execute "UPDATE organizations SET term='IX' where parent_id IS NULL AND active='f'"
    execute "UPDATE organizations SET term='X'  where parent_id IS NULL AND active='t'"    
  end

  def self.down
    remove_column :organizations, :term
  end
end