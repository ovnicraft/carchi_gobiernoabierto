class SocialNetworksManagement < ActiveRecord::Migration
  def self.up
    create_table :snetworks do |t|
      t.integer :sorganization_id
      t.string :url
      t.string :label
    end  
    
    create_table :sorganizations do |t|
      t.integer :department_id
      t.string :name_es
      t.string :name_eu
      t.string :name_en
      t.string :icon_file_name
      t.string :icon_content_type
      t.integer :icon_file_size
      t.datetime :icon_updated_at
    end
  end

  def self.down
    drop_table :snetworks
    drop_table :sorganizations
  end
end
