class AddBulletinEmailToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :bulletin_email, :string
  end

  def self.down
    remove_column :users, :bulletin_email
  end
end
