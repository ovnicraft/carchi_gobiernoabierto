class AddFieldsToNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :show_in_irekia, :boolean, :default => true
    add_column :documents, :show_in_agencia, :boolean, :default => true
    execute "UPDATE documents SET show_in_irekia='t', show_in_agencia='t' WHERE type='News'"
    
    add_column :documents, :department_id, :integer
    execute 'ALTER TABLE documents ADD CONSTRAINT doc_dep_id_fk FOREIGN KEY (department_id) REFERENCES departments(id)'
    first_department = Department.find(:first)
    Document.update_all("department_id=#{first_department.id}")
    
    
    add_column :documents, :cortes_path, :string
    add_column :documents, :totales_path, :string
    add_column :documents, :recursos_path, :string
    add_column :documents, :grabacion_completa_path, :string
    add_column :documents, :speaker_eu, :string
    add_column :documents, :speaker_en, :string
    rename_column :documents, :speaker, :speaker_es
    
    add_column :documents, :cover_photo_file_name, :string
    add_column :documents, :cover_photo_content_type, :string
    add_column :documents, :cover_photo_file_size, :integer
    add_column :documents, :cover_photo_updated_at, :datetime
  end

  def self.down
    remove_column :documents, :cover_photo_file_name
    remove_column :documents, :cover_photo_content_type
    remove_column :documents, :cover_photo_file_size
    remove_column :documents, :cover_photo_updated_at
    
    rename_column :documents, :speaker_es, :speaker
    remove_column :documents, :speaker_en
    remove_column :documents, :speaker_eu
    remove_column :documents, :grabacion_completa_path
    remove_column :documents, :recursos_path
    remove_column :documents, :totales_path
    remove_column :documents, :cortes_path
    remove_column :documents, :department_id
    remove_column :documents, :show_in_agencia
    remove_column :documents, :show_in_irekia
  end
end
