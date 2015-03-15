class AddTweetsToHeadlines < ActiveRecord::Migration
  def self.up
    execute "UPDATE headlines SET source_item_id = source_item_id || 'xx'"
    add_column :headlines, :tweets, :integer
  end

  def self.down
    remove_column :headlines, :tweets
  end
end
