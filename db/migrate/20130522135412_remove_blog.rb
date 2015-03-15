class RemoveBlog < ActiveRecord::Migration
  def self.up
    counter = 0
    Document.select("id, multimedia_path").where("type='Post'").each do |post|
      Comment.delete_all("commentable_id=#{post.id} AND commentable_type='Document'")
      post.destroy
      counter += 1
    end
    puts "Destroyed #{counter} posts"
  end

  def self.down
  end
end
