class AddAbuseCounterToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :abuse_counter, :integer, :default => 0
    Comment.update_all "abuse_counter=0"
    
    execute 'ALTER TABLE comments ALTER COLUMN abuse_counter SET NOT NULL'
  end

  def self.down
    remove_column :comments, :abuse_counter
  end
end
