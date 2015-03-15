class AddFieldsForUserTypes < ActiveRecord::Migration
  def self.up
    # For journalists
    add_column :users, :media, :string
    # For colaborators and editors
    add_column :users, :organization, :string
    # For jefes de prensa
    add_column :users, :department_id, :integer    
  end

  def self.down
    # For journalists
    remove_column :users, :media
    # For colaborators and editors
    remove_column :users, :organization
    # For jefes de prensa
    remove_column :users, :department_id
    
  end
end
