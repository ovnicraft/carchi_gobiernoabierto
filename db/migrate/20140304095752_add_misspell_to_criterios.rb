class AddMisspellToCriterios < ActiveRecord::Migration
  def self.up
    add_column :criterios, :misspell, :string
  end

  def self.down
    remove_column :criterios, :misspell
  end
end
