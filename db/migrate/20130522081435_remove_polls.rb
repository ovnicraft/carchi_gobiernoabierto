class RemovePolls < ActiveRecord::Migration
  def self.up
    Tagging.delete_all("taggable_type='Poll'")
    drop_table :poll_answers
    drop_table :poll_options
    drop_table :polls
  end

  def self.down
  end
end
