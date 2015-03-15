class AddIphoneToCriterios < ActiveRecord::Migration
  def self.up
    add_column :criterios, :iphone, :boolean, :default => false
  end

  def self.down
    remove_column :criterios, :iphone
  end
end
