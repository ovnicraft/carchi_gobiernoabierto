class CreateDepartmentsSchedulesForNewDepts < ActiveRecord::Migration
  def self.up
    Department.active.each do |dept|
      if s = Schedule.find_by_department_id(dept.id)
        p "La Agenda de #{dept.name} ya existe"
      else
        p "Creando agenda de #{dept.name}"
        Schedule.create(:name => "Agenda #{dept.name}", :short_name => dept.tag_name.gsub(/^_/,'a_'), :department_id => dept.id)
      end
    end
    
  end

  def self.down
  end
end
