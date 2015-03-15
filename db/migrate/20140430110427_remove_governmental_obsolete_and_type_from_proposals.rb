class RemoveGovernmentalObsoleteAndTypeFromProposals < ActiveRecord::Migration
  def change
    Proposal.delete_all("governmental_obsolete='t'")
    remove_column :proposals, :governmental_obsolete
    remove_column :proposals, :type
  end
end
