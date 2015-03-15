class RemoveDraftAndStateFromScheduleEvents < ActiveRecord::Migration
  def self.up
    remove_column :schedule_events, :draft
    remove_column :schedule_events, :state
  end

  def self.down
    add_column :schedule_events, :state, :string,               :limit => 30
    add_column :schedule_events, :draft, :boolean,                              :default => false, :null => false
  end
end
