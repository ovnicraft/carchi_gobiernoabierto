class CreateDepartmentSchedules < ActiveRecord::Migration
  def self.up
    add_column :schedules, :department_id, :integer
    
    Schedule.reset_column_information
    Department.all.each do |dept|
      Schedule.create(:name => "Agenda #{dept.name}", :short_name => dept.tag_name.gsub(/^_/,'a_'), :department_id => dept.id)
    end
  end

  def self.down
    remove_column :schedules, :department_id
    Department.all.each do |dept|
      if s = Schedule.find_by_short_name(dept.tag_name.gsub(/^_/,'a_'))
        s.destroy
      end
    end
  end
end
