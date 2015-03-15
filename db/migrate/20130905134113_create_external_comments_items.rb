class CreateExternalCommentsItems < ActiveRecord::Migration
  def self.up
    create_table :external_comments_items do |t|
      t.references :client
      t.text :url
      t.text :content_path
      t.integer :comments_count
      t.timestamps
    end
  end

  def self.down
    drop_table :external_comments_items
  end
end
