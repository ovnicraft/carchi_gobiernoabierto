class AddAreas < ActiveRecord::Migration
  def self.up
    # Quito las áreas que aquí y las añado desde un rake k. 
  end

  def self.down
    Area.destroy_all
  end
end
