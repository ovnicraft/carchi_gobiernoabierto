class AddDeptEntityRelatedFields < ActiveRecord::Migration
  def self.up
    # Internal number of the dept.
    add_column :departments, :internal_id, :integer
    add_column :departments, :icon_id, :integer        
  end

  def self.down
    remove_column :departments, :icon_id
    remove_column :departments, :position
  end
end
