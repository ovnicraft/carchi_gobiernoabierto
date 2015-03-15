class CreateFollowings < ActiveRecord::Migration
  def self.up
    create_table :followings, :force => true do |t|
      t.integer :user_id
      t.integer :followed_id
      t.string :followed_type
      t.timestamps
    end
  end

  def self.down
    drop_table :followings
  end
end