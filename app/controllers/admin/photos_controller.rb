# Controlador para administrar las fotos de la fototeca
class Admin::PhotosController < Sadmin::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_photo_tag_list]
  auto_complete_for :photo, :tag_list_es

  before_filter :access_to_photos_required
  # before_filter :get_album, :only => [:destroy, :update]

  def index
    @album = Album.find(params[:album_id])
    @aphotos = @album.album_photos.ordered_by_title.to_a.paginate :joins => :photo, :page => params[:page]
  end

  # Listado de fotos que no pertenecen a ningún álbum
  def orphane
    @photos = Photo.paginate :page => params[:page], :order => "created_at DESC",
      :conditions => "NOT EXISTS (SELECT 1 FROM album_photos WHERE album_photos.photo_id=photos.id)"
  end

  # Vista de una foto
  def show
    if params[:album_id]
      @album = Album.find(params[:album_id])
      @photo = @album.photos.find(params[:id])

      all_photos = @album.photos.ordered_by_title
      @next_photo = all_photos[all_photos.index(@photo) + 1]
      @prev_photo = all_photos[all_photos.index(@photo) - 1] unless all_photos.index(@photo) == 0
    else
      @photo = Photo.find(params[:id])
    end
  end

  def new
    @photo = Photo.new
  end

  # Importar fotos nuevas, tanto en un álbum nuevo como en uno existente
  def create
    @photo = Photo.new(photo_params.merge(:file_path => params[:dir_path], :dir_path => params[:dir_path]))
    if @photo.valid? && params[:dir_path].present?
      if params[:album_id].to_i == 0
        @album = Album.create(:title_es => params[:photo][:title_es], :title_eu => params[:photo][:title_eu], :title_en => params[:photo][:title_en])
      else
        @album = Album.find(params[:album_id])
      end
      import_photos
    else
      @photo.errors.add(:base, "No ha indicado ningún directorio") if params[:dir_path].blank?
      render :action => "new" and return
    end
  end

  # Modificar una foto
  def edit
    @album = Album.find(params[:album_id]) if params[:album_id]
    @photo = Photo.find(params[:id])
  end

  # Actualizar los atributos de una foto
  def update
    @album = Album.find(params[:album_id]) if params[:album_id]
    @photo = Photo.find(params[:id])
    if @photo.update_attributes(photo_params)
      if @album && @album.photos.exists?(@photo.id)
        redirect_to admin_photo_path(@photo, :album_id => @album.id)
      else
        redirect_to admin_photo_path(@photo)
      end
    else
      render :action => "new"
    end
  end

  # Modificar los atributos de varias fotos
  def batch_edit
    @photos = Photo.find(params[:ids])
  end

  # Actualizar los atributos de varias fotos
  def batch_update
    @photos = Photo.find(params[:photos].keys.collect(&:to_i))
    begin
      Photo.transaction do
        @photos.each_with_index do |photo, index|
          batch_photo_params = params.require(:photos).require(photo.id.to_s).permit(:title_es, :title_eu, :title_en, :city, :province_state, :country, :album_ids, :tag_list)
          photo.update_attributes!(batch_photo_params)
        end
        flash[:notice] = "Las fotos se han actualizado correctamente"
        redirect_to admin_albums_path
      end
    rescue => e
      flash[:error] = "Las fotos no se han actualizado"
      render :action => "batch_edit"
    end
  end

  # Busca fotos en el directorio especificado
  def find_photos
    @photo = Photo.new(:dir_path => params[:dir_path])
  end

  # Eliminar una foto
  def destroy
    @album = Album.find(params[:album_id]) if params[:album_id]
    @photo = Photo.find(params[:id])
    if @photo.destroy
      flash[:notice] = "La foto ha sido eliminada"
      if @album
        redirect_to admin_album_path(@album)
      else
        redirect_to orphane_admin_photos_path
      end
    else
      flash[:error] = "La foto no ha podido ser eliminada"
      if @album
        redirect_to admin_album_photo_path(@album, @photo)
      else
        redirect_to orphane_admin_photos_path
      end
    end
  end

  # Lista de tags para el campo de auto-complete
  def auto_complete_for_photo_tag_list
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:photo][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end
  end


  private

  # Coge el álbum al que pertenecen las fotos, si lo tiene
  def get_album
    @album = Album.find(params[:album_id])
  end

  # Importa las fotos del directorio especificado y genera los diferentes tamaños
  def import_photos
    @n_imported_files = 0
    @errored_files = {}
    @created_photos = []

    full_dir = File.join(Photo::PHOTOS_PATH, params[:dir_path])
    @found_files = Dir.glob(File.join(full_dir, "*.jpg"))

    dirs = @found_files.collect {|f| File.dirname(f)}.uniq
    Tools::Multimedia::PHOTOS_SIZES.each do |size, dummy|
      dirs.each {|d| FileUtils.mkdir_p File.join(d, size.to_s)}
    end

    @found_files.each do |f|
      dirname = File.dirname(f)
      filename = File.basename(f)
      ffile = f.sub(/^#{Photo::PHOTOS_PATH}/, '')
      unless Photo.exists?(:file_path => ffile)
        Tools::Multimedia::PHOTOS_SIZES.each do |size, geometry|
          begin
            IrekiaThumbnail.make(f, geometry, size)
          rescue IrekiaThumbnailError => err
            logger.error err
          end
        end
        iptc_data = extract_iptc_data(dirname, filename)
        new_photo = Photo.new(photo_params.merge(:dir_path => params[:dir_path], :file_path => ffile, :album_ids => [@album.id],
          :tag_list => iptc_data[:keywords], :date_time_original => iptc_data[:date_time_original],
          :date_time_digitalized => iptc_data[:date_time_digitalized],
          :exif_image_length => iptc_data[:exif_image_length],
          :city => iptc_data[:city],
          :province_state => iptc_data[:province_state],
          :country => iptc_data[:country]))
        if new_photo.save
          @created_photos << new_photo
          @n_imported_files += 1
        else
          @errored_files[new_photo.file_path] = new_photo.errors.full_messages.collect {|m| m}.join(',')
        end
      end
    end
  end

  # Extrae de los campos EXIF de la foto, la información de lugar, fecha, palabras clave, etc
  def extract_iptc_data(dirname, filename)
    tags = []
    data = {}
    identify_output_file = "#{dirname}/identify-#{filename}.txt"
    system "identify -verbose #{dirname}/#{filename} > #{identify_output_file}"
    if File.exists?(identify_output_file)
      lines = File.open(identify_output_file).readlines
      begin
        lines.each do |line|
          if m = line.strip.match(/\AKeyword\:\s(.+)\z/)
            tags << m[1]
          elsif m = line.strip.match(/\ADate Time Original\:\s(.+)\Z/)
            data[:date_time_original] = DateTime.parse(m[1].gsub(/^(\d{4})\:(\d{2})\:(\d{2})/, '\1-\2-\3'))
          elsif m = line.strip.match(/\ADate Time Digitized\:\s(.+)\Z/)
            data[:date_time_digitalized] = DateTime.parse(m[1].gsub(/^(\d{4})\:(\d{2})\:(\d{2})/, '\1-\2-\3'))
          elsif m = line.strip.match(/\AExif Image Width\:\s(.+)\Z/)
            data[:exif_image_width] = m[1]
          elsif m = line.strip.match(/\AExif Image Length\:\s(.+)\Z/)
            data[:exif_image_length] = m[1]
          elsif m = line.strip.match(/\ACity\:\s(.+)$/)
            data[:city] = m[1]
          elsif m = line.strip.match(/\AProvince State\:\s(.+)\Z/)
            data[:province_state] = m[1]
          elsif m = line.strip.match(/\ACountry\:\s(.+)\Z/)
            data[:country] = m[1]
          end
        end
      rescue => e
        puts "There were some errors reading the file #{e}"
      end

      tag_list = tags.join(', ')
      FileUtils.rm(identify_output_file)
      return data.merge(:keywords => tag_list)
    end
  end

  # Construye los breadcrubs de todas las acciones
  def make_breadcrumbs
    @breadcrumbs_info = [["Administración", admin_path], ["Fototeca", admin_albums_path]]
    if @album
      @breadcrumbs_info << [@album.title, admin_album_path(@album)]
      if @photo && !@photo.new_record?
        @breadcrumbs_info << [@photo.title, admin_album_photo_path(@album, @photo)]
      end
    end

    @breadcrumbs_info
  end

  def set_current_tab
    @current_tab = :photos
  end

  def photo_params
    params.require(:photo).permit(:title_es, :title_eu, :title_en, :city, :province_state, :country, :tag_list, :album_ids => [])
  end

end
