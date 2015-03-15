class AddTitleAndCommentsClosedForExternalCommentsItems < ActiveRecord::Migration
  def self.up
    add_column :external_comments_items, :title, :text
    add_column :external_comments_items, :comments_closed, :boolean, :null => false, :default => false
    
    execute "UPDATE external_comments_items SET title=url, comments_closed='f'"
  end

  def self.down
    remove_column :external_comments_items, :comments_closed
    remove_column :external_comments_items, :title
  end
end