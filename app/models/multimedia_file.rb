#
# Clase para los ficheros multimedia. 
# Para inicializar el objeto hay que pasar el path relativo a Document::MULTIMEDIA_PATH del fichero.
#

class MultimediaFile
  attr_accessor :name
  attr_accessor :url
  attr_accessor :path
  attr_accessor :size
  attr_accessor :file_type

  def initialize(file_path_or_adocument, opts={})
    if file_path_or_adocument.is_a?(String)
      file_path = file_path_or_adocument.gsub(/^#{Document::MULTIMEDIA_PATH}/,'')
      absolute_path = File.join(Document::MULTIMEDIA_PATH, file_path)
      pathname = Pathname.new(absolute_path)      

      self.path = file_path
      self.name = pathname.basename.to_s
      self.url = File.join(Document::MULTIMEDIA_URL, self.path)
      self.size = pathname.size()      
      self.file_type = pathname.extname()
    else
      if file_path_or_adocument.is_a?(Attachment)
        adocument = file_path_or_adocument
        self.path = adocument.file.path
        self.name = adocument.file_file_name
        self.url  = adocument.file.url
        self.size = adocument.file_file_size
        self.file_type = adocument.file_content_type.split('/').last
      end
      if file_path_or_adocument.is_a?(Paperclip::Attachment)
        attachment = file_path_or_adocument
        self.path = attachment.path
        self.name = attachment.original_filename
        self.url  = attachment.url
        self.size = attachment.instance.cover_photo_file_size
        self.file_type = attachment.instance.cover_photo_content_type.split('/').last        
      end
    end
  end
  
end
