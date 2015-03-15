class AddSourceToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :document_id, :integer
    Video.order("id").each do |video|
      puts "Buscando noticia con el video #{video.video_path}"
      dirname = Pathname.new(video.video_path).dirname
      if source = News.find_by_multimedia_dir(dirname.to_s)
        puts "Encontrada la noticia #{source.id} con directorio #{source.multimedia_dir}"
        video.update_attribute(:document_id, source.id)
      end
      puts "------------"
    end
  end

  def self.down
    remove_column :videos, :document_id
  end
end
