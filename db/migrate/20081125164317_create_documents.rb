class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :title_es
      t.string :title_eu
      t.text :body_es
      t.text :body_eu
      t.boolean :has_comments, :null => false, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
