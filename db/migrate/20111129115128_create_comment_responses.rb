class CreateCommentResponses < ActiveRecord::Migration
  def self.up
    create_table :comment_responses do |t|
      t.references :comment
      t.references :organization
      t.date       :deadline
      t.string     :status, :limit => 10
      t.string     :citizen_id
      t.datetime   :send_at
      t.timestamps
    end
  end

  def self.down
    drop_table :comment_responses
  end
end
