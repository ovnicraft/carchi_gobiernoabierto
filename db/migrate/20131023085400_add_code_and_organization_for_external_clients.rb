class AddCodeAndOrganizationForExternalClients < ActiveRecord::Migration
  def self.up
    add_column :external_comments_clients, :code, :string
    add_column :external_comments_clients, :organization_id, :integer
    add_column :external_comments_clients, :notes, :text
    
    execute "UPDATE external_comments_clients SET code=id"
    
    execute 'ALTER TABLE external_comments_clients ADD CONSTRAINT fk_client_organization_id FOREIGN KEY (organization_id) REFERENCES organizations(id)'
    
    add_index :external_comments_clients, :code, :unique => true, :name => "client_code_idx"
  end

  def self.down
    remove_column :external_comments_clients, :notes
    remove_index :external_comments_clients, :code, :unique => true, :name => "client_code_idx"
    remove_column :external_comments_clients, :organization_id
    remove_column :external_comments_clients, :code
  end
end