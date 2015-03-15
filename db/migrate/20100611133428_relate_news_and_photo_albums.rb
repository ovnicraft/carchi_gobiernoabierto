class RelateNewsAndPhotoAlbums < ActiveRecord::Migration
  def self.up
    add_column :photos, :document_id, :integer
    Photo.order("id").each do |photo|
      puts "Buscando noticia con la foto #{photo.file_path}"
      dirname = Pathname.new(photo.file_path).dirname
      if source = News.find_by_multimedia_dir(dirname.to_s)
        puts "Encontrada la noticia #{source.id} con directorio #{source.multimedia_dir}"
        photo.update_attribute(:document_id, source.id)
      end
      puts "------------"
    end

    add_column :albums, :document_id, :integer
    add_column :albums, :body_es, :string
    add_column :albums, :body_eu, :string
    add_column :albums, :body_en, :string
    add_column :albums, :draft, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :albums, :draft
    remove_column :albums, :body_es
    remove_column :albums, :body_eu
    remove_column :albums, :body_en
    remove_column :albums, :document_id
    remove_column :photos, :document_id
  end
end
