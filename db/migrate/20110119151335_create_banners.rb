class CreateBanners < ActiveRecord::Migration
  def self.up
    create_table :banners do |t|
      t.string :alt_es
      t.string :alt_eu
      t.string :alt_en
      t.string :url_es
      t.string :url_eu
      t.string :url_en
      t.string :logo_es_file_name
      t.string :logo_es_content_type
      t.integer :logo_es_file_size
      t.datetime :logo_es_updated_at 
      t.string :logo_eu_file_name
      t.string :logo_eu_content_type
      t.integer :logo_eu_file_size
      t.datetime :logo_eu_updated_at
      t.string :logo_en_file_name
      t.string :logo_en_content_type
      t.integer :logo_en_file_size
      t.datetime :logo_en_updated_at
      t.integer :position, :default => 0
      t.boolean :active
      t.timestamps
    end  
    
  end

  def self.down
    drop_table :banners
  end
end
