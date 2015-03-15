class MakeProposalVotesPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :proposal_votes, :votable_type, :string
    rename_column :proposal_votes, :proposal_id, :votable_id
    
    execute "UPDATE proposal_votes SET votable_type = 'Contribution'"
    
    add_column :contributions, :proposal_votes_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :contributions, :proposal_votes_count
    
    rename_column :proposal_votes, :votable_id, :proposal_id
    
    execute "UPDATE proposal_votes SET votable_type = 'Proposal'"
    
    remove_column :proposal_votes, :votable_type
  end
end