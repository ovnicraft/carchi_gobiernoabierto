class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name_es, :null => false
      t.string :name_eu, :null => false
      t.integer :parent_id
      t.references :tree, :null => false
      t.integer :position
      t.timestamps
    end
    
    execute 'ALTER TABLE categories ADD CONSTRAINT fk_cat_parent_id FOREIGN KEY (parent_id) REFERENCES categories(id)'
    execute 'ALTER TABLE categories ADD CONSTRAINT fk_cat_tree_id FOREIGN KEY (tree_id) REFERENCES trees(id)'
  end

  def self.down
    drop_table :categories
  end
end
