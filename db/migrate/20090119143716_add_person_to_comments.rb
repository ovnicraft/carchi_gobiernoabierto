class AddPersonToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :person_id, :integer
  end

  def self.down
    remove_column :comments, :person_id
  end
end
