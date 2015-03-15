class AddLocaleToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :locale, :string, :limit => 2, :null => false, :default => "es"
  end

  def self.down
    remove_column :comments, :locale
  end
end
