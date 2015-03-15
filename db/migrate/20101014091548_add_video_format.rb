class AddVideoFormat < ActiveRecord::Migration
  def self.up
    add_column :videos, :display_format, :string, :limit => 5
    
    execute "UPDATE videos SET display_format='43'"
  end

  def self.down
    remove_column :videos, :display_format
  end
end
