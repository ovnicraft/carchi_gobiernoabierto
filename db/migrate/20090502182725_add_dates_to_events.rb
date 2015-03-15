class AddDatesToEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :starts_at, :datetime
    add_column :documents, :ends_at, :datetime
    add_column :documents, :place, :string
  end

  def self.down
    remove_column :documents, :place
    remove_column :documents, :ends_at
    remove_column :documents, :starts_at
  end
end
