class CreateDebateStages < ActiveRecord::Migration
  def self.up
    create_table :debate_stages do |t|
      t.references :debate
      
      t.string  :stage, :limit => 20, :null => false
      t.date    :starts_on
      t.date    :ends_on
      t.boolean :has_comments, :default => true, :null => false
      
      t.timestamps
    end
    
    execute 'ALTER TABLE debate_stages ADD CONSTRAINT fk_debate_id FOREIGN KEY (debate_id) REFERENCES debates(id)'
  end

  def self.down
    drop_table :debate_stages
  end
end
