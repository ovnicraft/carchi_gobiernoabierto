class CreateTagEjes < ActiveRecord::Migration
  def self.up
    create_table :tag_ejes do |t|
      t.string :sanitized_name
      t.integer :eje_id
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_ejes
  end
end
