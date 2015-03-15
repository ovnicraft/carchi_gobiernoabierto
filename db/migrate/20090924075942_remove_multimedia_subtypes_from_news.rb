class RemoveMultimediaSubtypesFromNews < ActiveRecord::Migration
  def self.up
    add_column :documents, :multimedia_dir, :string
    add_column :documents, :multimedia_path, :string

    News.order("created_at").each do |news|
      if m = news.title_es.match(/([a-z]{7,})/i)
        news.multimedia_dir = m.to_a[1].tildes.downcase
      else
        news.multimedia_dir = "noticia"
      end
      date = news.created_at.to_date
      news.multimedia_path = "#{date.year}/#{date.strftime("%m")}/#{date.strftime("%d")}/#{news.multimedia_dir}/"
      while !news.save
        puts "#{news.multimedia_dir} no vale"
        news.multimedia_dir = news.multimedia_dir + "_1"
        news.multimedia_path = "#{date.year}/#{date.strftime("%m")}/#{date.strftime("%d")}/#{news.multimedia_dir}/"
      end
      
      FileUtils.mkdir_p(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "solo_irekia"))
      FileUtils.mkdir_p(File.join(Document::MULTIMEDIA_PATH, news.multimedia_path, "solo_agencia"))
      puts "Noticia #{news.id}:
        Antiguo video: #{news.video_path}
        Antiguo audio: #{news.audio_path}
        Antiguo fotos: #{news.photos_path}
        Antiguo cortes: #{news.cortes_path}
        Antiguo totales: #{news.totales_path}
        Antiguo recursos: #{news.recursos_path}
        Antiguo grabacion completa: #{news.grabacion_completa_path}
        Nuevo directorio: #{news.multimedia_path}
        -----------------
        "
    end
    
    Page.order("created_at").each do |page|
      if m = page.title_es.match(/([a-z]{7,})/i)
        page.multimedia_dir = m.to_a[1].tildes.downcase
      else
        page.multimedia_dir = "pagina"
      end

      page.multimedia_path = "paginas/#{page.multimedia_dir}/"
      while !page.save
        page.multimedia_dir = page.multimedia_dir + "_1"
        page.multimedia_path = "paginas/#{page.multimedia_dir}/"
      end
      FileUtils.mkdir_p(File.join(Document::MULTIMEDIA_PATH, page.multimedia_path))
      
      puts "Página #{page.id}: 
        Antiguo video: #{page.video_path}
        Antiguo audio: #{page.audio_path}
        Antiguo fotos: #{page.photos_path}
        Nuevo directorio: #{page.multimedia_path}
        -----------------
        "
    end
    
    remove_column :documents, :video_path
    remove_column :documents, :audio_path
    remove_column :documents, :photos_path
    remove_column :documents, :files_path
    remove_column :documents, :cortes_path
    remove_column :documents, :totales_path
    remove_column :documents, :recursos_path
    remove_column :documents, :grabacion_completa_path
    
  end

  def self.down
    remove_column :documents, :multimedia_dir
    remove_column :documents, :multimedia_path
    add_column :documents, :video_path, :string
    add_column :documents, :audio_path, :string
    add_column :documents, :photos_path, :string
    add_column :documents, :files_path, :string
    add_column :documents, :cortes_path, :string
    add_column :documents, :totales_path, :string
    add_column :documents, :recursos_path, :string
    add_column :documents, :grabacion_completa_path, :string
  end
end
