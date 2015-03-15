class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :document_id, :null => false
      t.string :name, :null => false
      t.string :email, :null => false
      t.text :body
      t.string :status, :null => false, :default => 'pendiente'
      t.timestamps
    end
    execute 'ALTER TABLE comments ADD CONSTRAINT comment_doc_fk FOREIGN KEY (document_id) REFERENCES documents(id)'
  end

  def self.down
    drop_table :comments
  end
end
