class AddShowInIrekiaForStreamFlows < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :show_in_irekia, :boolean, :default => false
  end

  def self.down
    remove_column :stream_flows, :show_in_irekia
  end
end
