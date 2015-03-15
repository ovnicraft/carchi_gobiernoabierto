class RemoveCommentResponses < ActiveRecord::Migration
  def change
    drop_table :comment_responses
    drop_table :comment_response_requests
    remove_column :comments, :rrcc_answered_at
  end
end
