class AugmentCriterioTitle < ActiveRecord::Migration
  def self.up
    change_column :criterios, :title, :text
  end

  def self.down
  end
end
