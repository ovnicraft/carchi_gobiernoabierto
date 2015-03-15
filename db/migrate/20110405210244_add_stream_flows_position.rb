class AddStreamFlowsPosition < ActiveRecord::Migration
  def self.up
    add_column :stream_flows, :position, :integer, :null => :false, :default => 0
    
    n = 0
    StreamFlow.order('code').each do |sf|
      sf.update_attribute(:position, n)
      n += 1
    end
  end

  def self.down
    remove_column :stream_flows, :position
  end
end