class CreateRatings < ActiveRecord::Migration
  def self.up
    remove_column :documents, :positive_votes
    remove_column :documents, :negative_votes
    
    add_column :documents, :has_ratings, :boolean, :default => true
    Document.update_all("has_ratings='t'")
    execute 'ALTER TABLE documents ALTER COLUMN has_ratings SET NOT NULL'
    
    create_table :ratings do |t|
      t.integer :rating # You can add a default value here if you wish
      t.integer :rateable_id, :null => false
      t.string  :rateable_type, :null => false
    end
    add_index :ratings, [:rateable_id, :rating] # Not required, but should help more than it hurts
  end

  def self.down
    remove_column :documents, :has_ratings
    drop_table :ratings
  end
end
