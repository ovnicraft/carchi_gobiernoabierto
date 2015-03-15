class AddOnlyTitleToCriterios < ActiveRecord::Migration
  def self.up
    add_column :criterios, :only_title, :boolean, :default => false
  end

  def self.down                                 
    remove_column :criterios, :only_title
  end
end
