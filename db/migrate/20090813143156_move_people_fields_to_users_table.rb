class Person < ActiveRecord::Base ; end;
class MovePeopleFieldsToUsersTable < ActiveRecord::Migration
  def self.up
    add_column :users, :alias, :string
    add_column :users, :last_names, :string
    add_column :users, :name_visible, :boolean, :default => true
    add_column :users, :last_names_visible, :boolean, :default => true
    add_column :users, :raw_location, :string
    add_column :users, :lat, :decimal
    add_column :users, :lng, :decimal
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :country_code, :string
    add_column :users, :zip, :string
    add_column :users, :user_ip, :string
    add_column :users, :photo_file_name, :string
    add_column :users, :photo_content_type, :string
    add_column :users, :photo_file_size, :integer
    add_column :users, :photo_updated_at, :datetime
    add_column :users, :url, :string
    
    
    add_column :comments, :user_id, :integer
    Comment.where("person_id is not null").each do |comment|
      person = Person.find(comment.person_id)
      comment.user_id = User.find(person.user_id).id
      comment.save
    end
    remove_column :comments, :person_id
    
    
    add_column :proposals, :user_id, :integer
    Proposal.where("person_id is not null").each do |proposal|
      person = Person.find(proposal.person_id)
      proposal.user_id = User.find(person.user_id).id
      proposal.save
    end
    remove_column :proposals, :person_id
    
    
    # La columna role desaparece y la cambiamos por type.
    # Tendremos subclases para cada tipo de usuario
    add_column :users, :type, :string
    # This does not work (?)
    # User.all.each do |user|
    #   user.update_attribute(:type, user.role.camelize)
    #   user.save!
    # end
    execute "UPDATE users SET type='Person' WHERE role='user'"
    execute "UPDATE users SET type='Admin' WHERE role='admin'"
    remove_column :users, :role
    
    Person.all.each do |person|
      user = User.find(person.user_id)
      user.name = person.name unless person.name.blank?
      user.alias = person.alias
      user.last_names = person.last_names
      user.name_visible = person.name_visible
      user.last_names_visible = person.last_names_visible
      user.raw_location = person.raw_location
      user.lat = person.lat
      user.lng = person.lng
      user.city = person.city
      user.state = person.state
      user.country_code = person.country_code
      user.zip = person.zip
      user.user_ip = person.user_ip
      user.photo_file_name = person.photo_file_name
      user.photo_content_type = person.photo_content_type
      user.photo_file_size = person.photo_file_size
      user.photo_updated_at = person.photo_updated_at
      user.url = person.url
      user.save
    end
    
    drop_table :people    

  end

  def self.down
    
    add_column :comments, :person_id, :integer
    remove_column :comments, :user_id

    add_column :proposals, :person_id, :integer
    remove_column :proposals, :user_id
    
    create_table "people", :force => true do |t|
      t.string   "alias"
      t.string   "name"
      t.string   "last_names"
      t.string   "raw_location"
      t.boolean  "name_visible",                      :default => true
      t.boolean  "last_names_visible",                :default => true
      t.decimal  "lat"
      t.decimal  "lng"
      t.string   "city"
      t.string   "state"
      t.string   "country_code"
      t.string   "zip"
      t.string   "user_ip"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "photo_file_name"
      t.string   "photo_content_type"
      t.integer  "photo_file_size"
      t.datetime "photo_updated_at"
      t.string   "bio",                :limit => 300
      t.boolean  "featured",                          :default => false, :null => false
      t.string   "url"
    end
    
    add_column :users, :role, :string, :limit => 50, :default => "user"
    remove_column :users, :type
    remove_column :users, :alias
    remove_column :users, :last_names
    remove_column :users, :name_visible
    remove_column :users, :last_names_visible
    remove_column :users, :raw_location
    remove_column :users, :lat
    remove_column :users, :lng
    remove_column :users, :city
    remove_column :users, :state
    remove_column :users, :country_code
    remove_column :users, :zip
    remove_column :users, :user_ip
    remove_column :users, :photo_file_name
    remove_column :users, :photo_content_type
    remove_column :users, :photo_file_size
    remove_column :users, :photo_updated_at
    remove_column :users, :url
    
  end
end
