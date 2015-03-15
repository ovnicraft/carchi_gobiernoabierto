class CreateTwitterMentions < ActiveRecord::Migration
  def self.up
    create_table :twitter_mentions do |t|
      t.string :tweet_id, :null => false
      t.string :user_name, :null => false
      t.text :tweet_text, :null => false
      t.text :tweet_entities
      t.text :tweet_decoded_urls
      t.datetime :tweet_published_at
      t.timestamps
    end
    
    add_index :twitter_mentions, [:tweet_id], :unique => true
  end

  def self.down
    remove_index :twitter_mentions, :column => [:tweet_id]
    drop_table :twitter_mentions
  end
end