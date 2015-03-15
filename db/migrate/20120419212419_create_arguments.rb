class CreateArguments < ActiveRecord::Migration
  def self.up
    create_table :arguments do |t|
      t.references :proposal, :null => false
      t.references :user, :null => false
      t.integer :value, :null => false
      t.string :reason, :null => false
      t.datetime :published_at
      t.datetime :rejected_at

      t.timestamps
    end
  end

  def self.down
    drop_table :arguments
  end
end
