class AddForwardToZuzeneanToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :zforwarded_at, :datetime
    add_column :comments, :zforwarded_to, :integer
  end

  def self.down
    remove_column :comments, :zforwarded_to
    remove_column :comments, :zforwarded_at
  end
end
