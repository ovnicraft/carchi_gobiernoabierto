class AddAttachmentsIndices < ActiveRecord::Migration
  def self.up
    add_index :attachments, [:document_id, :show_in_irekia], :name => "show_in_irekia_idx"
    add_index :attachments, [:document_id, :show_in_agencia], :name => "show_in_agencia_idx"
    add_index :attachments, [:document_id, :file_content_type], :name => "content_type_idx"
  end

  def self.down
    remove_index :attachments, :name => "show_in_irekia_idx"
    remove_index :attachments, :name => "show_in_agencia_idx"
    remove_index :attachments, :name => "content_type_idx"
  end
end