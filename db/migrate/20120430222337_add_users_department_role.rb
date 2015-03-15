class AddUsersDepartmentRole < ActiveRecord::Migration
  def self.up
    add_column :users, :department_role, :string, :limit => 30
  end

  def self.down
    remove_column :users, :department_role
  end
end