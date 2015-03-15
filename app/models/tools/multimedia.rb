# Métodos compartidos entre todas las clases que tienen directorio multimedia (Noticia y Debate)
module Tools::Multimedia
  def self.included(base)
    base.after_destroy :move_multimedia_files_to_trash
  end
  # OLD_PHOTOS_SIZES = {:n85 => "85x85>", :n120 => "120x120>", :n320 => "320x320>", :n700 => "700x700>", :iphone => "70x70#", :n189 => "189x142#", :n95 => "95x64#", :iframe => "610x344#"}
  # , :n189 => "189x142#", :n95 => "95x64#", :iframe => "610x344#"

  PHOTOS_SIZES = {:n70 => "70", :n136 => "136x136>", :bulletin_270 => "270", :n320 => "320x240>", :n770 => "770x433>", :iphone => "70x70#", :square => "90x90#"}
  PHOTOS_SIZES.freeze

  # Construye la ruta absoluta al directorio de contenidos multimedia de un documento.
  #
  # Las News y las Page de la web, tienen contenido multimedia (videos para streaming y para descarga,
  # audios y mini-galería de fotos). Es contenido variable y se produce anterior o posteriormente a la
  # propia noticia, y por personas diferentes a las que pueden crear el contenido de la noticia.
  #
  # Además, estos contenidos pueden ser muy pesados, por lo que subirlos a la web a través de formularios
  # podría dar problemas de timeouts con algunos proxies.
  #
  # Por todo ello, este contenido se sube al servidor a través de SFTP y se enlaza con la noticia indicando
  # en <tt>multimedia_dir</tt> el lugar donde se encuentran los ficheros (ruta relativa al home del usuario SFTP)
  # y <tt>full_multimedia_path</tt> devuelve la ruta absoluta.
  def full_multimedia_path
    File.join(class_multimedia_path, multimedia_path)
  end

  def class_multimedia_path
    self.class.base_class.const_get('MULTIMEDIA_PATH')
  end

  attr_reader :videos
  # Devuelve todos los videos disponibles para este documento,
  # separados por idiomas:
  # ==== Ejemplos de uso:
  # * <tt>videos[:featured][:es]:</tt> video destacado para la versión en castellano
  # * <tt>videos[:list][:es]:</tt> videos secundarios para la versión en castellano
  def videos
    unless @videos
      @videos = {:list => {:es => [], :eu => [], :en => []},
                :featured => {:es => nil, :eu => nil, :en => nil},
                :mpg => {:es => [], :eu => [], :en => []}}

      return @videos if self.multimedia_path.blank?
      list_of_videos = []
      # Todos los vídeos
      list_of_videos = Dir.glob(full_multimedia_path + "*.flv") + Dir.glob(full_multimedia_path + "*.mpg") +
                       Dir.glob(full_multimedia_path + "*.mpeg") + Dir.glob(full_multimedia_path + "*.mp4") +
                       Dir.glob(full_multimedia_path + "*.mov")
      list_of_videos = list_of_videos.collect {|a| Pathname.new(a).relative_path_from(Pathname.new(class_multimedia_path)).to_s}

      # logger.info "AAAAAAAAAAAAAAAAAAA #{list_of_videos.join(", ")}"

      Document::LANGUAGES.each do |l|
        # Meto en cada idioma solo los que acaban en "_<idioma>.flv"
        list_of_videos.each do |video|
          if m = video.match(/(.+)_#{l}.flv/)
            if m.to_a[1][-1..-1].eql?("1")
              # Si acaba en "1", es el video de portada
              @videos[:featured][l.to_sym] = video # Esti: esto sobra .sub(class_multimedia_path, '')
            else
              @videos[:list][l.to_sym] << video # Esti: esto sobra .sub(class_multimedia_path, '')
            end
          elsif m = video.match(/(.+)_#{l}\.(mpg|mpeg|mov|mp4)/)
            @videos[:mpg][l.to_sym] << video #Esti: esto sobra .sub(class_multimedia_path, '')
          end
        end
        list_of_videos = list_of_videos - (@videos[:list][l.to_sym] + [@videos[:featured][l.to_sym]] + @videos[:mpg][l.to_sym])
      end

      Document::LANGUAGES.each do |l|
        # Meto en todos, los que no acaban en "_<idioma>.flv"
        list_of_videos.each do |video|
          if video.match(/1.flv$/)
            # Si el nombre es "*1.flv", es la de portada
            if @videos[:featured][l.to_sym].nil?
              @videos[:featured][l.to_sym] = video # Esti: esto sobra .sub(class_multimedia_path, '')
            end
          elsif video.match(/(mpg|mpeg|mov|mp4)$/)
            @videos[:mpg][l.to_sym] << video # Esti: esto sobra .sub(class_multimedia_path, '')
          else
            @videos[:list][l.to_sym] << video # Esti: esto sobra .sub(class_multimedia_path, '')
          end
        end
      end

      Document::LANGUAGES.each do |l|
        if @videos[:featured][l.to_sym].nil?
          first_flv = @videos[:list][l.to_sym].select {|v| v.match(/.flv$/)}.first
          @videos[:featured][l.to_sym] = first_flv
          @videos[:list][l.to_sym].delete(first_flv)
        end
      end

    end

    return @videos
  end

  def videos_flv
    self.videos[:list][I18n.locale.to_sym] + [self.featured_video]
  end

  def videos_mpg
    self.videos[:mpg][I18n.locale.to_sym]
  end

  # Indica si hay videos secundarios para este documento y en el idioma actual
  def has_videos?
    videos[:list][I18n.locale.to_sym].length > 0 || videos[:mpg][I18n.locale.to_sym].length > 0
  end

  def has_professional_videos?
    videos[:mpg][I18n.locale.to_sym].length > 0
  end

  # Indica si hay video destacado para este documento y en el idioma actual
  def has_video?(locale=I18n.locale.to_sym)
    !featured_video(locale).nil?
  end

  def has_video_with_captions?(locale=I18n.locale)
    self.webtv_videos.present? && self.webtv_videos.select{|a| a if a.translated_to?(locale) && a.captions_available?}.present?
  end

  # Devuelve el video destacado para este documento y en el idioma actual
  def featured_video(locale=I18n.locale.to_sym)
    videos[:featured][locale]
  end


  attr_reader :audios
  # Devuelve la lista de audios para este documento
  # ==== Ejemplo:
  # <tt>audios[:es]:</tt> audios en castellano
  def audios
    unless @audios
      @audios = {:es => [], :eu => [], :en => [], :all => []}

      return @audios if self.multimedia_path.blank?

      # Lista de todos los audios en <dir>/*.mp3
      list_of_audios = Dir.glob(full_multimedia_path + "*.mp3")
      list_of_audios = list_of_audios.collect {|a| Pathname.new(a).relative_path_from(Pathname.new(class_multimedia_path)).to_s}

      Document::LANGUAGES.each do |l|
        # Meto en cada idioma solo los que acaban en "_<idioma>.mp3"
        @audios[l.to_sym] = list_of_audios.select {|a| a.match("_#{l}.mp3")}
        list_of_audios = list_of_audios - @audios[l.to_sym]
      end

      Document::LANGUAGES.each do |l|
        @audios[l.to_sym] = @audios[l.to_sym] + list_of_audios
      end
      @audios[:all] = @audios.values.flatten.uniq
    end
    return @audios
  end

  # Devuelve la lista de audios para este documento que se han subido como documento adjunto
  # ==== Ejemplo:
  # <tt>attached_audios[:es]:</tt> audios en castellano
  # NOTA: Aunque está definida como atributo, la lista de audios que coge cada vez que se llama a este método.
  # Así ocupa menos memoría.
  def attached_audios(locale = I18n.locale)
    attached_audios = {:es => [], :eu => [], :en => [], :all => []}

    self.attachments.where("((file_content_type ilike 'audio/%') OR (file_content_type ilike 'application/x-mp3'))").order("created_at").each do |at|
      attached_audios.keys.each do |lang|
        attached_audios[lang].push(at) if lang != :all && at.send("show_in_#{lang}?")
      end
    end
    attached_audios[:all] = attached_audios.values.flatten.uniq
    return attached_audios
  end

  #
  #
  #
  def all_audios(locale = I18n.locale)
    lsym = locale.to_sym
    self.audios[lsym] + self.attached_audios[lsym]
  end

  def attached_files(lang=I18n.locale)
    attached_files = []
    self.attachments.where("((file_content_type not ilike 'audio/%') AND (file_content_type not ilike 'application/x-mp3'))").order("created_at").each do |at|
      attached_files.push(at) if at.send("show_in_#{lang}?")
    end

    return attached_files
  end

  # Indica si hay audios para este documento en el idioma actual
  def has_audios?
    audios[I18n.locale.to_sym].length + attached_audios[I18n.locale.to_sym].length > 0
  end

  # Indica si hay fotos para este documento en el idioma actual
  def has_photos?
    photos.length > 0
  end

  attr_reader :photos
  # Devuelve la lista de fotos disponibles .
  # Devuelve sólo la lista de fotos originales. Los tamaños adicionales se guardan con el mismo nombre en subdirectorios
  # con nombres iguales a los keys de Tools::Multimedia::PHOTOS_SIZES
  # Se excluyen las fotos de portada de todos los videos flv.
  def photos
    @photos = [] if self.multimedia_path.blank?
    unless @photos
      @photos = Dir.glob(full_multimedia_path + "*.jpg")

      @photos = @photos - video_previews_in_all_languages if has_video?
    end
    return @photos
  end

  # Indica si este documento tiene documentos adjuntos
  def has_files?
    attachments.count > 0
  end

  # Métodos para acceder y generar el zip de los contenidos (photos, audios, videos y videos_mpg)
  ['photos', 'videos', 'videos_mpg', 'audios'].each do |type|
    Document::LANGUAGES.each do |locale|
      define_method "zip_#{type}_file_#{locale}" do
        File.join(class_multimedia_path, self.multimedia_path, File.join(self.multimedia_path, type, "#{locale.to_s}.zip").gsub('/', '_'))
      end
    end

    define_method "zip_#{type}" do |locale=I18n.locale.to_sym|
      return false unless self.multimedia_path.present?

      multimedia_dir = File.join(class_multimedia_path, self.multimedia_path)
      items_list = case type
      when 'photos'
        self.photos.map {|f| f.gsub(multimedia_dir, '')}.join(' ')
      when 'videos'
        (self.videos[:list][locale] + [self.featured_video]).compact.map {|a| a.gsub(self.multimedia_path, '')}.join(' ')
      when 'audios'
        # self.audios[locale].map {|a| a.gsub(self.multimedia_path, '')}.join(' ')
        self.all_audios(locale).map {|a| a.is_a?(Attachment) ? a.file.path : a.gsub(self.multimedia_path, '')}.join(' ')
      when 'videos_mpg'
        self.videos[:mpg][locale].map {|a| a.gsub(self.multimedia_path, '')}.join(' ')
      end
      unless File.exists?(self.send("zip_#{type}_file_#{locale}")) && (File.new(self.send("zip_#{type}_file_#{locale}")).ctime >= File.new(multimedia_dir).ctime)
        system "cd #{multimedia_dir} && zip #{File.join(self.multimedia_path, type, "#{locale.to_s}.zip").gsub('/', '_')} #{items_list}"
      else
        return true
      end
    end
  end


  # Directorio donde se guardan los adjuntos borrados de este documento
  def dir_for_deleted
    dummy, year, month_day_dir = self.multimedia_path.match(/^([^\/]+)\/(.+)$/).to_a
    if year && month_day_dir
      dir_for_deleted = File.join(class_multimedia_path, year, "borradas", month_day_dir)
    else
      dir_for_deleted = File.join(class_multimedia_path, "borradas")
    end
  end

  private

  # Crea el directorio para los contenidos multimedia de esta noticia a partir de lo
  # especificado en el parametro <tt>multimedia_dir</tt>.
  # Se llama desde before_save.
  #
  # Ver también documentación de Document#full_multimedia_path
  def set_and_create_multimedia_path
    if (self.new_record? && self.multimedia_dir.present?) || (self.multimedia_dir_changed? && self.multimedia_dir_was.blank? && self.multimedia_dir.present?)
      # if m = self.multimedia_dir.match(/^(\d{4}\/\d{2}\/\d{2}\/)/)
        self.multimedia_path = self.multimedia_dir.dup
        if self.is_a?(Page)
          self.multimedia_path = File.join("paginas", self.multimedia_dir)
        elsif self.is_a?(Debate)
          self.multimedia_path = File.join("debates", self.multimedia_dir)
        else
          self.multimedia_path << "/" unless self.multimedia_path.match(/\/$/)
        end

        logger.info "Create multimedia path: #{self.multimedia_path} for #{self.class} id #{self.id}"

      # else
      #   date = self.published_at ? self.published_at.to_date : Date.today
      #   self.multimedia_path = "#{date.year}/#{date.strftime("%m")}/#{date.strftime("%d")}/#{self.multimedia_dir}/"
      # end
      m_path_array = self.multimedia_path.split('/')
      common_path = File.join(class_multimedia_path, m_path_array)
      FileUtils.mkdir_p(common_path)
      # FileUtils.chmod 0777, common_path # , :verbose => true

      # FileUtils.chmod_R 0777, root_path_for_permissions # , :verbose => true

      # Tenemos que poner world-writeable-permissions en todo el path que estamos creando
      partial_path_for_permissions = File.join(class_multimedia_path, m_path_array[0])
      FileUtils.chmod 0777, partial_path_for_permissions
      (1..(m_path_array.length-1)).each do |i|
        partial_path_for_permissions = File.join(partial_path_for_permissions, m_path_array[i])
        FileUtils.chmod 0777, partial_path_for_permissions
      end


      if Document.exists?(:multimedia_path => self.multimedia_path)
        self.errors.add(:multimedia_dir, I18n.t('activerecord.errors.messages.taken'))
        return false
      else
        return self.multimedia_path
      end
    else
      return true
    end
  end

  # Devuelve un array con los nombres de los ficheros de preview de un video en todos los idiomas,
  # independientemente de si existen o no.
  # ==== Ejemplo:
  # Si el preview en castellano es <tt>preview_es.jpg</tt>, devuelve <tt>['preview_es.jpg', 'preview_eu.jpg', 'preview_en.jpg', 'preview.jpg']</tt>
  # Se usa para quitar de las fotos de una noticia, las que corresponden a las portadas de los videos
  def video_previews_in_all_languages
    previews = []
    (videos[:list][:es] + [videos[:featured][:es]]).compact.each do |video|
      filename = video.sub(/#{Pathname.new(video).extname}$/, '')
      video_filename_without_extension = filename.gsub(/_(#{Document::LANGUAGES.join('|')})$/, '')
      previews << "#{class_multimedia_path}#{video_filename_without_extension}.jpg"
      Document::LANGUAGES.each do |l|
        previews<< "#{class_multimedia_path}#{video_filename_without_extension}_#{l}.jpg"
      end
    end
    return previews
  end

  # Mueve a la "papelera" los ficheros multimedia cuando se borra una noticia/pagina
  # Se llama desde after_destroy
  def move_multimedia_files_to_trash
    if self.multimedia_path

      FileUtils.mkdir_p(dir_for_deleted)
      FileUtils.mv(Dir.glob(File.join(class_multimedia_path, self.multimedia_path, "*.*")), dir_for_deleted)

      logger.info "Moviendo #{File.join(class_multimedia_path, self.multimedia_path, "*.*")} a #{dir_for_deleted}"

      FileUtils.rm_rf(File.join(class_multimedia_path, self.multimedia_path))

      # Los videos de la webtv dejarán de funcionar porque están en el mismo directorio
      self.webtv_videos.update_all("published_at=NULL, document_id=NULL") if self.respond_to?('webtv_videos')
      self.gallery_photos.update_all("document_id=NULL") if self.respond_to?('gallery_photos')
      self.album.update_attributes(:document_id => nil, :draft => true) if self.respond_to?('album') && self.album
    end
    return true
  end

end
