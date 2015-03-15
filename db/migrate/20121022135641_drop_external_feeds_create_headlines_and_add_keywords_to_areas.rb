class DropExternalFeedsCreateHeadlinesAndAddKeywordsToAreas < ActiveRecord::Migration
  def self.up                         
    drop_table :external_feeds
    drop_table :headlines
    
    add_column :areas, :headline_keywords, :text
    create_table :headlines, :force => true do |t|
      t.text :title
      t.text :body
      t.string :source_item_type
      t.string :source_item_id
      t.string :locale
      t.string :url
      t.string :media_name
      t.datetime :published_at
      t.boolean :draft
      t.float :score
      t.timestamps
    end
  end

  def self.down                                  
    drop_table :headlines
    remove_column :areas, :headline_keywords
    create_table :headlines do |t|
      t.integer  :feed_id
      t.text     :title
      t.datetime :published_at
      t.text     :text
      t.text     :description
      t.text     :url
      t.string   :source_url
      t.string   :category_name
      t.string   :section_name
      t.string   :section_url
      t.string   :media_name
      t.string   :media_rank
      t.string   :media_audience
      t.string   :search_exp
      t.string   :image_url
      t.string   :value
      t.string   :locale, :size => 2
      t.string   :source_item_id
      t.text     :source_item_info
      t.timestamps
    end
    create_table :external_feeds do |t|
      t.string :url, :null => false
      t.string :title
      t.string :provider
      t.string :encoding
      t.string :interval
      t.integer :organization_id
      t.datetime :last_import_at
      t.string   :last_import_status
      t.timestamps
    end
  end
end