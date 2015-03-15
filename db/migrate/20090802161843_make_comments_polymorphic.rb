class MakeCommentsPolymorphic < ActiveRecord::Migration
  def self.up
    rename_column :comments, :document_id, :commentable_id
    add_column :comments, :commentable_type, :string
    Comment.update_all("commentable_type='Document'")
    execute 'ALTER TABLE comments DROP CONSTRAINT comment_doc_fk'
  end

  def self.down
    remove_column :comments, :commentable_type
    rename_column :comments, :commentable_id, :document_id
  end
end
