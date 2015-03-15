class RemoveAgenciaFromDocuments < ActiveRecord::Migration
  def self.up

    execute "UPDATE documents set published_at = NULL WHERE draft='t'"
    execute "UPDATE documents set published_at = NULL WHERE show_in_irekia='f' AND show_in_agencia='t'"
    remove_column :documents, :show_in_agencia
    remove_column :documents, :show_in_irekia
    remove_column :documents, :draft
    remove_column :documents, :state
    remove_column :documents, :is_private_deprecated
    
  end

  def self.down
    add_column :documents, :show_in_agencia, :boolean,   :default => true
    add_column :documents, :show_in_irekia, :boolean,   :default => true
    add_column :documents, :draft, :boolean,   :default => true
    add_column :documents, :state, :string,   :limit => 30
    add_column :documents, :is_private_deprecated, :boolean, :default => true
  end
end
