class AddOpenInAgencia < ActiveRecord::Migration
  def self.up
      add_column :documents, :open_in_agencia, :boolean, :default => false
      Document.update_all("open_in_agencia=false")
      if News.exists?(7433)    
        noticia = News.find(7433)
        noticia.open_in_agencia=true
        noticia.save
      end
      execute 'ALTER TABLE documents ALTER COLUMN open_in_agencia SET NOT NULL'
    end

    def self.down
      remove_column :documents, :open_in_agencia
  end
end
