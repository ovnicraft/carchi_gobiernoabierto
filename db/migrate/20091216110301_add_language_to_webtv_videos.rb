class AddLanguageToWebtvVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :show_in_es, :boolean, :null => false, :default => true
    add_column :videos, :show_in_eu, :boolean, :null => false, :default => true
    add_column :videos, :show_in_en, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :videos, :show_in_es
    remove_column :videos, :show_in_eu
    remove_column :videos, :show_in_en
  end
end
