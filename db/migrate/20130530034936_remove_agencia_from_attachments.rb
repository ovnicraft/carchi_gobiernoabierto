class RemoveAgenciaFromAttachments < ActiveRecord::Migration
  def self.up
    remove_column :attachments, :show_in_irekia
    remove_column :attachments, :show_in_agencia
  end

  def self.down
    add_column :attachments, :show_in_agencia, :boolean,   :default => true
    add_column :attachments, :show_in_irekia, :boolean,    :default => true
  end
end
