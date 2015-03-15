class AddPollCommentsFields < ActiveRecord::Migration
  def self.up
    add_column :polls, :has_comments, :boolean, :default => true
    add_column :polls, :comments_closed , :boolean, :default => false
    add_column :polls, :comments_count, :integer, :default => 0
    
    Poll.update_all("comments_count=0")
  end

  def self.down
    remove_column :polls, :comments_closed 
    remove_column :polls, :has_comments
    remove_column :polls, :comments_count
  end
  
end
