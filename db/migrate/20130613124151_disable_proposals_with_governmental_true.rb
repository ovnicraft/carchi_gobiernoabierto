class DisableProposalsWithGovernmentalTrue < ActiveRecord::Migration
  def self.up
    Proposal.where("governmental = 't'").each do |prop|
      prop.update_attributes(:published_at => nil, :status => 'pendiente_traspaso_a_debates')
    end
    
    rename_column :contributions, :governmental, :governmental_obsolete
  end

  def self.down
    rename_column :contributions, :governmental_obsolete, :governmental
    Proposal.where("governmental = 't'").each do |prop|
      prop.update_attributes(:published_at => prop.updated_at, :status => 'aprobado')
    end
    
  end
end