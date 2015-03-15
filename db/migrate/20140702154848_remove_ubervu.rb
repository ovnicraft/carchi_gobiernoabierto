class RemoveUbervu < ActiveRecord::Migration
  def change
    drop_table :ubervu_entries
  end
end
