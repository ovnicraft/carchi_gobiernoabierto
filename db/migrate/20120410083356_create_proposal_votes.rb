class CreateProposalVotes < ActiveRecord::Migration
  def self.up
    create_table :proposal_votes do |t|
      t.references :proposal, :null => false
      t.references :user, :null => false
      t.integer :value, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :proposal_votes
  end
end
