class AugmentCommentRefererSize < ActiveRecord::Migration
  def self.up
    change_column :comments, :referrer, :text
  end

  def self.down
    change_column :comments, :referrer, :string
  end
end