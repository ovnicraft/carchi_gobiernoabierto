class AddCriterioToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :criterio_id, :integer
  end

  def self.down                             
    remove_column :tags, :criterio_id
  end
end
