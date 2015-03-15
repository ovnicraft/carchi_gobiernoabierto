class AddEventForStreamFlows < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :event_id, :integer
  end

  def self.down
    remove_column :stream_flows, :event_id
  end
end
