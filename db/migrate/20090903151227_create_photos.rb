class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.string :title_es
      t.string :title_eu
      t.string :title_en
      t.string  :file_path, :null => false
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
  end

  def self.down
    drop_table :photos
  end
end
