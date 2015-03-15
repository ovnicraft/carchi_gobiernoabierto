class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.string :name
      t.text   :description
      t.string :short_name
      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
