class CreateProposals < ActiveRecord::Migration
  def self.up
    create_table :proposals do |t|
      t.string :name
      t.string :email
      t.string :title_es
      t.string :title_eu
      t.string :title_en
      t.text :body_es
      t.text :body_eu
      t.text :body_en
      t.boolean :draft, :null => false, :default => false
      t.string :url
      t.string :status, :null => false, :default => "pendiente"
      t.string :user_ip
      t.integer :person_id
      t.boolean :governmental, :null => false, :default => false
      t.boolean :has_comments, :null => false, :default => true
      t.boolean :comments_closed, :null => false, :default => false
      t.integer :comments_count, :null => false, :default => 0
      t.datetime :published_at
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
    add_index :proposals, [:status], :name => "proposal_status_idx"
  end

  def self.down
    remove_index :proposals, :name => :proposal_status_idx
    drop_table :proposals
  end
end
