class CreateTrees < ActiveRecord::Migration
  def self.up
    create_table :trees do |t|
      t.string :name_es, :null => false
      t.string :name_eu, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :trees
  end
end
