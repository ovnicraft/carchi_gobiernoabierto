class RemovePlainPassword < ActiveRecord::Migration
  def self.up
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_sent_at, :datetime
    remove_column :users, :plain_password
  end

  def self.down
    remove_column :users, :password_reset_token
    remove_column :users, :password_reset_sent_at
    add_column :users, :plain_password, :string
  end
end
