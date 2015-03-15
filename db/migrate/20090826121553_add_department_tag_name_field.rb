class AddDepartmentTagNameField < ActiveRecord::Migration
  def self.up
    add_column :departments, :tag_name, :string, :limit => 50
    Department.all.each do |dept|
      dept.update_attribute(:tag_name, Department::DEFAULT_TAGS[dept.id])
    end
    
  end

  def self.down
    remove_column :departments, :tag_name
  end
end
