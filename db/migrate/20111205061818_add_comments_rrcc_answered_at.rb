class AddCommentsRrccAnsweredAt < ActiveRecord::Migration
  def self.up
    add_column :comments, :rrcc_answered_at, :datetime
    add_column :comment_responses, :answer_comment_id, :integer
  end

  def self.down
    remove_column :comment_responses, :answer_comment_id
    remove_column :comments, :rrcc_answered_at
  end
end