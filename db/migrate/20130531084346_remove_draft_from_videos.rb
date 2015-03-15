class RemoveDraftFromVideos < ActiveRecord::Migration
  def self.up
    Video.where("draft='t' and published_at is not null").each do |video|
      video.destroy
    end
    remove_column :videos, :draft
  end

  def self.down
    add_column :videos, :draft, :boolean,                              :default => false, :null => false
  end
end
