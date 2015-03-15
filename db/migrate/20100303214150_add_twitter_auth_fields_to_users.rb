class AddTwitterAuthFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :screen_name, :string
    add_column :users, :atoken, :string
    add_column :users, :asecret, :string
    
    execute "ALTER TABLE comments ALTER COLUMN email DROP NOT NULL"
  end

  def self.down
    remove_column :users, :screen_name
    remove_column :users, :asecret
    remove_column :users, :atoken
    
    execute "ALTER TABLE comments ALTER COLUMN email SET NOT NULL"
  end
end
