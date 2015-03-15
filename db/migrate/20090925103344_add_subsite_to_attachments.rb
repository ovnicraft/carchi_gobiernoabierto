class AddSubsiteToAttachments < ActiveRecord::Migration
  def self.up
    add_column :attachments, :show_in_irekia, :boolean, :default => true
    add_column :attachments, :show_in_agencia, :boolean, :default => true
  end

  def self.down
    remove_column :attachments, :show_in_irekia
    remove_column :attachments, :show_in_agencia
  end
end
