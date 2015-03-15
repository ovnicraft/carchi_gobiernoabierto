class CreateDocumentTweets < ActiveRecord::Migration
  def self.up
    create_table :document_tweets do |t|
      t.references :document, :null => false
      t.string :tweet_account
      t.datetime :tweet_at
      t.datetime :tweeted_at
      t.string :tweet_locale
      t.timestamps
    end
    execute 'ALTER TABLE document_tweets ADD CONSTRAINT fk_dt_document_id FOREIGN KEY (document_id) REFERENCES documents(id)'
  end

  def self.down
    drop_table :document_tweets
  end
end
