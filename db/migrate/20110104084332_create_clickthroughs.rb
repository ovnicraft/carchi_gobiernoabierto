class CreateClickthroughs < ActiveRecord::Migration
  def self.up
    create_table :clickthroughs do |t|
      t.string  :source_type, :null => false
      t.integer :source_id, :null => false
      t.string  :target_type, :null => false
      t.integer :target_id, :null => false
      t.string  :locale, :null => false
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :clickthroughs
  end
end
