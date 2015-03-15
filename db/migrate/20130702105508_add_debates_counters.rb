class AddDebatesCounters < ActiveRecord::Migration
  def self.up
    # add_column :debates, :votes_count, :integer, :default => 0, :null => false
    rename_column :debates, :proposal_votes_count, :votes_count
  end

  def self.down
    # remove_column :debates, :votes_count
    rename_column :debates, :votes_count, :proposal_votes_count
  end
end