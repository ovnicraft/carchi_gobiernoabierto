class AddExternalCommentsItemsContentLocalId < ActiveRecord::Migration
  def change
    add_column :external_comments_items, :content_local_id, :string 
  end
end
