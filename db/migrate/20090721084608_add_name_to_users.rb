class AddNameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :name, :string
    User.where("role='admin'").each do |user|
      if person = Person.find_by_user_id(user.id)
        user.name = person.public_name
        user.save
      else
        user.name = user.email
        user.save
      end
    end
    
    execute "ALTER TABLE users ALTER COLUMN role TYPE varchar(50)"
  end

  def self.down
    remove_column :users, :name
  end
end
