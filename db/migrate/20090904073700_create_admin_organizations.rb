class CreateAdminOrganizations < ActiveRecord::Migration
  def self.up
    
    create_table :organizations do |t|
      t.string  :name_es, :null => false
      t.string  :name_eu
      t.string  :name_en
      t.string  :type # Department o Entity
      t.string  :kind # Kind of dept: consejería, organismo, ente, sociedad, etc. 
      t.integer :position, :default => 0
      t.integer :internal_id
      t.integer :parent_id
      t.string  :tag_name
      t.references :icon
      t.timestamps
    end
    
    execute "INSERT INTO organizations (id, name_es, name_eu, name_en, tag_name) SELECT id, name_es, name_eu, name_en, tag_name FROM departments"
    execute "SELECT setval('organizations_id_seq', (select count(*) from organizations))"
    execute "UPDATE organizations SET type='Department', kind='Consejería'"
    
    # Documents should belong to organization, not department
    execute "ALTER TABLE documents DROP CONSTRAINT doc_dep_id_fk"
    rename_column :documents, :department_id, :organization_id
    execute "ALTER TABLE documents ADD CONSTRAINT doc_organization_id_fk FOREIGN KEY (organization_id) REFERENCES organizations(id)" 
 
    rename_table :departments, :xx_departments
  end

  def self.down
    rename_column :documents, :organization_id, :department_id
    rename_table :xx_departments, :departments
    drop_table :organizations
  end
end
