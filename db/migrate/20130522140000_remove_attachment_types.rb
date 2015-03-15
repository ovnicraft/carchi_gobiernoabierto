class RemoveAttachmentTypes < ActiveRecord::Migration
  def self.up
    Attachment.where("type='ATranscription'").each do |transcription|
      transcription.destroy
    end
    FileUtils.mv "#{Rails.root}/public/assets/a_documents", "#{Rails.root}/public/assets/attachments" if File.exists?("#{Rails.root}/public/assets/a_documents")
    # Make symlink from a_documents to attachments for possible links inside news body to keep on working 
    File.symlink("#{Rails.root}/public/assets/attachments", "#{Rails.root}/public/assets/a_documents") if File.exists?("#{Rails.root}/public/assets/attachments")
    remove_column :attachments, :type
    # To fix error in migrations order
    # UPDATE schema_migrations SET version = '20130522140000' where version='20130530033014';
  end

  def self.down
    add_column :attachments, :type, :string, :null => false
  end
end
