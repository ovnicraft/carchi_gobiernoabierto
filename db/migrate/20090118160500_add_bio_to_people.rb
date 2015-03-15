class AddBioToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :bio, :string, :limit => 300
    add_column :people, :featured, :boolean, :default => false
    Person.update_all("featured='f'")
    execute 'ALTER TABLE people ALTER COLUMN featured SET NOT NULL'
  end

  def self.down
    remove_column :people, :bio
    remove_column :people, :featured
  end
end
