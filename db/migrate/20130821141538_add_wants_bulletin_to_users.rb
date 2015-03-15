class AddWantsBulletinToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :wants_bulletin, :boolean, :null => false, :default => false
    add_column :users, :bulletin_sent_at, :datetime
  end

  def self.down
    remove_column :users, :bulletin_sent_at
    remove_column :users, :wants_bulletin
  end
end