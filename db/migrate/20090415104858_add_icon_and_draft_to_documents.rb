class AddIconAndDraftToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :icon_id, :integer
    execute 'ALTER TABLE documents ADD CONSTRAINT document_icon_fk FOREIGN KEY (icon_id) REFERENCES icons(id)'
    
    add_column :documents, :draft, :boolean, :default => true
    Document.update_all("draft='f'")
    execute 'ALTER TABLE documents ALTER COLUMN draft SET NOT NULL'
    
    add_column :documents, :positive_votes, :integer, :default => 0
    add_column :documents, :negative_votes, :integer, :default => 0
    Document.update_all("positive_votes=0, negative_votes=0")
    execute 'ALTER TABLE documents ALTER COLUMN positive_votes SET NOT NULL'
    execute 'ALTER TABLE documents ALTER COLUMN negative_votes SET NOT NULL'
    
  end

  def self.down
    remove_column :documents, :icon_id
    remove_column :documents, :draft
    
    remove_column :documents, :positive_votes
    remove_column :documents, :negative_votes
  end
end
