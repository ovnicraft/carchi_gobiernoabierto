class AddCommentsCounter < ActiveRecord::Migration
  def self.up
    add_column :documents, :comments_count, :integer, :default => 0
    
    News.reset_column_information
    News.all.each do |n|
      News.update_counters n.id, :comments_count => n.comments.length
    end
    Page.update_all("comments_count=0")
    Event.update_all("comments_count=0")
  end

  def self.down
    remove_column :documents, :comments_count
  end
end
