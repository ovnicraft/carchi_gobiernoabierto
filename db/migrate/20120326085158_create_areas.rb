class CreateAreas < ActiveRecord::Migration
  def self.up
    create_table :areas do |t|
      t.string :name_es, :null => false
      t.string :name_eu
      t.string :name_en
      t.text   :description_es
      t.text   :description_eu      
      t.text   :description_en
      t.integer :position, :default => 0
      t.string  :icon_file_name
      t.string  :icon_content_type
      t.integer :icon_file_size
      t.datetime  :icon_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :areas
  end
end
