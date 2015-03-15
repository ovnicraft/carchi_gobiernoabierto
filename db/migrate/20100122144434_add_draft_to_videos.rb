class AddDraftToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :draft, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :videos, :draft
  end
end
