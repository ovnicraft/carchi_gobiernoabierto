class AddIndexAttachmentsCreatedBy < ActiveRecord::Migration
  def self.up
    add_index :attachments, [:document_id, :type, :created_at], :name => "document_id_type_created_at_idx"
  end

  def self.down
    remove_index :attachments, :name => :document_id_type_created_at_idx
  end
end