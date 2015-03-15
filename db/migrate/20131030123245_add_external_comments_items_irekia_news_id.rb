class AddExternalCommentsItemsIrekiaNewsId < ActiveRecord::Migration
  def self.up
    add_column :external_comments_items, :irekia_news_id, :integer
  end

  def self.down
    remove_column :external_comments_items, :irekia_news_id
  end
end