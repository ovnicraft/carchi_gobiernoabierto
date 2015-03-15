class AddDurationToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :duration, :integer
    Video.all.each do |video|
      video.save
    end
  end

  def self.down
    remove_column :videos, :duration
  end
end
