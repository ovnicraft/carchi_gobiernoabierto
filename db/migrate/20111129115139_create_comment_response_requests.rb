class CreateCommentResponseRequests < ActiveRecord::Migration
  def self.up
    create_table :comment_response_requests do |t|
      t.references :comment_response
      t.string     :result
      t.text       :request_data
      t.string     :response_status      
      t.text       :response_body
      t.text       :response_error
      t.string     :citizen_id
      t.text       :answer_text
      t.string     :answer_type
      t.string     :registered_at
      t.string     :registration_id
      t.timestamps
    end
  end

  def self.down
    drop_table :comment_response_requests
  end
end
