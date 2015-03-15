class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments, :force => true do |t|
      t.string      :file_file_name, :string
      t.string      :file_content_type, :string
      t.integer     :file_file_size, :integer
      t.datetime    :file_updated_at, :datetime
      t.integer     :document_id, :null => false
      t.string      :type, :null => false
      t.boolean     :show_in_es, :default => true
      t.boolean     :show_in_eu, :default => true
      t.boolean     :show_in_en, :default => false
      t.integer     :created_by
      t.integer     :updated_by
      t.timestamps
    end
    execute 'ALTER TABLE attachments ADD CONSTRAINT att_doc_id_fk FOREIGN KEY (document_id) REFERENCES documents(id)'
  end

  def self.down
    drop_table :attachments
  end
end
