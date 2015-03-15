class AddSchedulesPermissionsRights < ActiveRecord::Migration
  def self.up
    add_column :schedules_permissions, :can_edit, :boolean, :default => true, :null => false
    add_column :schedules_permissions, :can_change_schedule, :boolean, :default => false, :null => false
    
    execute "UPDATE schedules_permissions SET can_edit='t', can_change_schedule='f'"
  end

  def self.down
    remove_column :schedules_permissions, :can_change_schedule
    remove_column :schedules_permissions, :can_edit
  end
end
