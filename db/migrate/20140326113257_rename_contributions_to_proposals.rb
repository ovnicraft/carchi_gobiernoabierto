class ProposalData < ActiveRecord::Base
   belongs_to :proposal
end

class RenameContributionsToProposals < ActiveRecord::Migration
  def up    
    add_column :contributions, :image, :string
    
    Proposal.reset_column_information
    ProposalData.all.each do |pd| 
      if pd.attributes["image"].present?
        #Proposal.find(pd.proposal_id).update_column(:image, pd.attributes["image"])
        execute "UPDATE contributions SET image = '#{pd.attributes['image']}' WHERE id = #{pd.proposal_id}"
      end
    end

    execute "UPDATE votes SET votable_type = 'Proposal' WHERE votable_type = 'Contribution'"
    execute "UPDATE notifications SET notifiable_type = 'Proposal' WHERE notifiable_type = 'Contribution'"
    execute "UPDATE attachments SET attachable_type = 'Proposal' WHERE attachable_type = 'Contribution'"
    execute "UPDATE taggings SET taggable_type = 'Proposal' WHERE taggable_type = 'Contribution'"
    execute "UPDATE comments SET commentable_type = 'Proposal' WHERE commentable_type = 'Contribution'"
    execute "UPDATE arguments SET argumentable_type = 'Proposal' WHERE argumentable_type = 'Contribution'"

    execute "UPDATE clickthroughs SET click_source_type = 'Proposal' WHERE click_source_type = 'Contribution'"
    execute "UPDATE clickthroughs SET click_target_type = 'Proposal' WHERE click_target_type = 'Contribution'"

    drop_table :proposal_datas
    drop_table :answer_requests
    drop_table :question_datas
    drop_table :answers
    rename_table :contributions, :proposals
  end

def down
end
end
