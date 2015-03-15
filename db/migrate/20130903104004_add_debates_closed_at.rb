class AddDebatesClosedAt < ActiveRecord::Migration
  def self.up
    add_column :debates, :finished_at, :datetime
  end

  def self.down
    remove_column :debates, :finished_at
  end
end