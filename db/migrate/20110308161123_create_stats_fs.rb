class CreateStatsFs < ActiveRecord::Migration
  def self.up
    create_table :stats_fs, :id => false do |t|
      t.integer :mpg, :null => false
      t.integer :mp3, :null => false
      t.timestamps
    end
    execute 'INSERT INTO stats_fs VALUES (0, 0, now(), now())'

  end

  def self.down
    drop_table :stats_fs
  end
end
