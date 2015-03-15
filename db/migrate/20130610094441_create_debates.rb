class CreateDebates < ActiveRecord::Migration
  def self.up
    create_table :debates do |t|
      t.string :title_es, :null => false, :limit => 400
      t.string :title_eu, :limit => 400      
      t.string :title_en, :limit => 400            
      t.text   :body_es
      t.text   :body_eu      
      t.text   :body_en     
      t.text   :description_es
      t.text   :description_eu      
      t.text   :description_en            
      t.string :hashtag
      t.date   :ends_on
      t.string :multimedia_dir 
      t.string :multimedia_path
      t.string :cover_image
      t.string :header_image
      t.boolean    :featured
      t.datetime   :published_at
      
      t.integer    :comments_count, :null => false, :default => 0
      t.integer    :proposal_votes_count, :null => false, :default => 0      
      t.integer    :arguments_count, :null => false, :default => 0            
      
      t.references :organization      
      t.references :page
      t.references :news      
      
      t.timestamps
    end
    
    execute 'ALTER TABLE debates ADD CONSTRAINT fk_organization_id FOREIGN KEY (organization_id) REFERENCES organizations(id)'
    execute 'ALTER TABLE debates ADD CONSTRAINT fk_page_id FOREIGN KEY (page_id) REFERENCES documents(id)'    
    execute 'ALTER TABLE debates ADD CONSTRAINT fk_news_id FOREIGN KEY (news_id) REFERENCES documents(id)'        
  end

  def self.down
    drop_table :debates
  end
end
