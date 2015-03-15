class AddPositionToDebateStages < ActiveRecord::Migration
  def self.up
    add_column :debate_stages, :position, :integer, :null => false, :default => 0
    execute "UPDATE debate_stages SET position=1 where label='presentation'"
    execute "UPDATE debate_stages SET position=2 where label='discussion'"
    execute "UPDATE debate_stages SET position=3 where label='contribution'"    
    execute "UPDATE debate_stages SET position=4 where label='conclusions'"        
  end

  def self.down
    remove_column :debate_stages, :position
  end
end