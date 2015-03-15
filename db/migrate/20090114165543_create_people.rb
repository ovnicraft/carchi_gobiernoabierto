class CreatePeople < ActiveRecord::Migration
  def self.up
    
    remove_column :users, :name
    
    create_table :people do |t|
      t.string      :alias, :name, :last_names, :raw_location
      t.boolean     :name_visible, :default => true
      t.boolean     :last_names_visible, :default => true
      t.decimal     :lat, :lng
      t.string      :city, :state, :country_code, :zip, :user_ip
      t.references  :user
      t.timestamps
    end
  end

  def self.down
    drop_table :people
    add_column :users, :name, :string
  end
end
