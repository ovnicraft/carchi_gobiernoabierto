class RenameProposalVotesToVotes < ActiveRecord::Migration
  def self.up
    rename_table 'proposal_votes', 'votes'
    rename_column :contributions, :proposal_votes_count, :votes_count
  end

  def self.down
    rename_table 'votes', 'proposal_votes'
    # rename_column :contributions, :votes_count, :proposal_votes_count
  end
end
