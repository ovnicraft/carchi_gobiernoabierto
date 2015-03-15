class CreateHeadlines < ActiveRecord::Migration
  def self.up
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
  end

  def self.down
    drop_table :headlines
  end
end
