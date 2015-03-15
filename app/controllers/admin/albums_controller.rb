# Controlador para la gestión de álbums en la WebTV
class Admin::AlbumsController < Sadmin::BaseController
  before_filter :access_to_photos_required
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_album_tag_list]
  
  # Listado de álbums
  def index

    @sort_order = params[:sort] ||  "publish"

    case @sort_order
    when "publish"
      order = "featured DESC, created_at DESC, title_es"
    when "title"
      order = "featured DESC, lower(tildes(title_es)), created_at DESC"
    end

    conditions = []
    if params[:q].present?
      conditions << "lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like '%#{params[:q].tildes.downcase}%'"
    end

    @albums = Album.where(conditions.join(' AND ')).paginate(page: params[:page]).reorder(order)
    
    # @orphane_photos_counter = Photo.count(:conditions => "NOT EXISTS (SELECT 1 FROM album_photos WHERE album_photos.photo_id=photos.id)")
    # @first_orphane_photo = Photo.find(:first, 
    #   :conditions => "NOT EXISTS (SELECT 1 FROM album_photos WHERE album_photos.photo_id=photos.id)", 
    #   :order => "created_at DESC")
  end
  
  # Vista de un álbum
  def show
    @album = Album.find(params[:id])
  end
  
  # Formulario de creación de álbum
  def new
    @album = Album.new
  end
  
  # Creación de un álbum
  def create
    @album = Album.new(album_params)
    if @album.save
      flash[:notice] = "El album se ha creado correctamente"
      redirect_to admin_album_path(@album)
    else
      render :action => "new"
    end
  end
  
  # Modificación de un álbum
  def edit
    @album = Album.find(params[:id])
  end
  
  # Actualización de un álbum
  def update
    @album = Album.find(params[:id])
    if @album.update_attributes(album_params)
      redirect_to admin_album_path(@album)
    else
      render :action => "new"
    end
  end
  
  # Eliminación de un álbum
  def destroy
    @album = Album.find(params[:id])
    if @album.destroy
      flash[:notice] = "El album ha sido eliminado"
      redirect_to admin_albums_path
    else
      flash[:error] = "El album no ha sido eliminado"
      redirect_to admin_album_path(@album)
    end
  end
  
  # Marca la foto elegida como portada para este álbum
  def choose_cover
    @album = Album.find(params[:id])
    @aphoto = @album.album_photos.find_by_photo_id(params[:photo_id])
    @previous_cover = @album.album_photos.find_by_cover_photo(true)
    unless @aphoto.update_attributes(:cover_photo => true)
      render :status => 402
    end
  end

  def publish
    @album = Album.find(params[:id])
    @album.update_attributes(:draft => false)
    redirect_to :back
  end
  
  # Auto complete para los tags
  def auto_complete_for_album_tag_list
    auto_complete_for_tag_list_first_beginning_then_the_rest(params[:album][:tag_list])
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end    
  end
  
  # Canales de la fototeca
  def channels
    @tree = Tree.find_albums_tree
    @title = "#{@tree.name_es} / #{@tree.name_eu}"
  end

  private
  # Construye los breadcrumbs para cada acción de los álbums
  def make_breadcrumbs
    @breadcrumbs_info = [["Administración", admin_path], ["Fototeca", admin_albums_path]]
    if @album && !@album.new_record?
      @breadcrumbs_info << [@album.title, admin_album_path(@album)]
    end
    @breadcrumbs_info
  end
  
  def set_current_tab
    @current_tab = :photos
  end

  def album_params
    params.require(:album).permit(:title_es, :title_eu, :title_en, :body_es, :body_eu, :body_en, :draft, :featured, :tag_list)
  end

end
