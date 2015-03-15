class CreateCachedKeys < ActiveRecord::Migration
  def self.up
    create_table :cached_keys do |t|
      t.string :cacheable_type
      t.integer :cacheable_id
      t.text :rake_es
      t.text :rake_eu
      t.text :rake_en
      t.timestamps
    end
  end

  def self.down
    drop_table :cached_keys
  end
end
