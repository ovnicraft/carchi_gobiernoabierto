class AddUsersPoliticiansData < ActiveRecord::Migration
  def self.up
    add_column :users, :public_role_es, :string
    add_column :users, :public_role_eu, :string    
    add_column :users, :public_role_en, :string        
    add_column :users, :description_es, :text
    add_column :users, :description_eu, :text
    add_column :users, :description_en, :text    
    add_column :users, :gc_id, :integer
  end

  def self.down
    remove_column :users, :gc_id
    remove_column :users, :description_es
    remove_column :users, :description_eu
    remove_column :users, :description_en        
    remove_column :users, :public_role_es
    remove_column :users, :public_role_eu
    remove_column :users, :public_role_en        
  end
end