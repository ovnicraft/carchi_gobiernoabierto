class CreateArticleSources < ActiveRecord::Migration
  def self.up
    create_table :article_sources do |t|
      t.integer :article_id
      t.text    :title
      t.string  :url
      t.string  :media
      t.integer :position, :null => false
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
  end

  def self.down
    drop_table :article_sources
  end
end
