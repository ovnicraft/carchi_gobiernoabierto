class CreateDebateEntities < ActiveRecord::Migration
  def self.up
    create_table :debate_entities do |t|
      t.references :debate, :null => false
      t.references :organization, :null => false
      t.integer :position, :default => 0, :null => false
      t.timestamps
    end
    
    execute 'ALTER TABLE debate_entities ADD CONSTRAINT fk_debate_entity_debate_id FOREIGN KEY (debate_id) REFERENCES debates(id)'
    execute 'ALTER TABLE debate_entities ADD CONSTRAINT fk_debate_entity_organization_id FOREIGN KEY (organization_id) REFERENCES organizations(id)'    
    
  end

  def self.down
    drop_table :debate_entities
  end
end
