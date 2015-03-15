class RemoveAliasFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :alias
    remove_column :users, :name_visible
    remove_column :users, :last_names_visible
  end

  def self.down
    add_column :users, :last_names_visible, :boolean,                      :default => true
    add_column :users, :name_visible, :boolean,                            :default => true
    add_column :users, :alias, :string
  end
end
