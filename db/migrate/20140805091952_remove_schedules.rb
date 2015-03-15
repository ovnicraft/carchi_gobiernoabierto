class RemoveSchedules < ActiveRecord::Migration
  def up
    drop_table :schedule_events
    drop_table :schedules
    remove_column :documents, :l_attends
  end
end
