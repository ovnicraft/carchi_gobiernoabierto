class RemoveArticles < ActiveRecord::Migration
  def self.up
    drop_table :article_sources

    Document.select("id, multimedia_path").where("type='Article'").each do |article|
      Comment.delete_all("commentable_id=#{article.id} AND commentable_type='Document'")
      article.destroy
    end
  end

  def self.down
  end
end
