class AddConsejoIdToNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :consejo_news_id, :integer
  end

  def self.down
    remove_column :documents, :consejo_news_id
  end
end
