class AddMobileSupportForStreamFlows < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :mobile_support, :boolean, :default => 'f', :null => false
    execute "UPDATE stream_flows SET mobile_support='f'"
  end

  def self.down
    remove_column :stream_flows, :mobile_support
  end
end