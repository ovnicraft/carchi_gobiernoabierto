class FixVideosVideoPath < ActiveRecord::Migration
  def change
    Video.where("video_path ilike '/%'").find_each do |v|
      v.update_column(:video_path, v.video_path.sub(/^\//,''))
    end
  end
end
