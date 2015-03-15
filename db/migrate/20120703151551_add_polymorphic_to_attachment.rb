class AddPolymorphicToAttachment < ActiveRecord::Migration
  def self.up
    rename_column :attachments, :document_id, :attachable_id
    add_column :attachments, :attachable_type, :string
    
    execute "UPDATE attachments SET attachable_type = 'Document'"
  end

  def self.down
    remove_column :attachments, :attachable_type
    rename_column :attachments, :attachable_id, :document_id
  end
end
