class CreateSchedulesPermissions < ActiveRecord::Migration
  def self.up
    create_table :schedules_permissions do |t|
      t.references :schedule
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :schedules_permissions
  end
end
