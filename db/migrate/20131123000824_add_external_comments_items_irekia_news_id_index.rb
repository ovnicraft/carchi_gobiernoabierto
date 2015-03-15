class AddExternalCommentsItemsIrekiaNewsIdIndex < ActiveRecord::Migration
  def self.up
    add_index :external_comments_items, [:irekia_news_id], :name => :external_comments_item_irekia_news_id_idx
  end

  def self.down
    remove_index :external_comments_items, :name => :external_comments_item_irekia_news_id_idx
  end
end