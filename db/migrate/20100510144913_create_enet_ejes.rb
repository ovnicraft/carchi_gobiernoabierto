class CreateEnetEjes < ActiveRecord::Migration
  def self.up
    create_table :enet_ejes do |t|
      t.string :short_name
      t.string :name
      t.string :code
      t.integer :level
      t.integer :parent_id
      t.integer :position
      t.string :sanitized_name
      t.timestamps
    end
  end

  def self.down
    drop_table :enet_ejes
  end
end
