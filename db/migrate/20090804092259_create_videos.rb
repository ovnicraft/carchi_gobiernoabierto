class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.string :title_es
      t.string :title_eu
      t.string :title_en
      t.string :video_path
      t.datetime :published_at
      t.integer :created_by
      t.integer :updated_by
      t.boolean :has_comments, :null => false, :default => true
      t.boolean :comments_closed, :null => false, :default => false
      t.integer :comments_count, :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end
