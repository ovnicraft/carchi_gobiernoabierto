class RenameDebateStageStageToLabel < ActiveRecord::Migration
  def self.up
    rename_column :debate_stages, :stage, :label
  end

  def self.down
    rename_column :debate_stages, :label, :stage
  end
end