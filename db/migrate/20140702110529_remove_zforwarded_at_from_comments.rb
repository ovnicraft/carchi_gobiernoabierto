class RemoveZforwardedAtFromComments < ActiveRecord::Migration
  def change
    remove_column :comments, :zforwarded_at, :datetime
    remove_column :comments, :zforwarded_to, :integer
  end
end
