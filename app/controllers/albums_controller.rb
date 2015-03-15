# Controlador para los álbums de la Fototeca
class AlbumsController < ApplicationController
  before_filter :get_context, :only => [:index]
  before_filter :get_criterio, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]

  def index
    prepare_albums(@context, request.xhr?)

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @albums, :type => 'album'}, :layout => false
        else
          render
        end
      end
    end
  end

  # Vista de un album de la fototeca
  def show
    begin
      @album = Album.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if can_edit?("videos")
        @album = Album.find(params[:id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    @photos = @album.photos.ordered_by_title.where(["cover_photo=?", false]).paginate(:page => params[:page])

    if params[:photo_id] && @photo = @album.photos.find(params[:photo_id])
      @photo_id = params[:photo_id]
      unless @photos.collect(&:id).include?(@photo_id.to_i)
        @photos.to_a.pop
        @photos << @photo
      end
    end

    @related_albums = Album.published.tagged_with(@album.area_tags).where("album_photos_count>0")
      .limit(8).reorder("featured DESC, created_at DESC")

    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace 'thumbnails', :partial => '/albums/thumbnails', :locals => {:photos => @photos}
        end
      }
    end
  
  end
  
  def cat
    @categories = Album.categories
    @category = Category.find(params[:id])
    @title = @category.name
    @albums = @category.albums.with_photos.published.paginate(:per_page => 12, :page  => params[:page] || 1)
    respond_to do |format|
      format.html
    end
  end
  
  private
  # Construye los breadcrumbs de cada acción de la fototeca
  def make_breadcrumbs
    if @context
      @breadcrumbs_info << [t('albums.title'), send("#{@context.class.to_s.downcase}_albums_path", @context)]
    else
      @breadcrumbs_info = [[t('photos.fototeca'), albums_path]]
      if @album
        @breadcrumbs_info << [@album.title, album_path(@album)]
      end
    end
    @breadcrumbs_info
  end
  
  def prepare_albums(context, is_xhr)
    @title = t('albums.fototeca')
    if context
      @title << " #{t('shared.from_context', :name => context.public_name)}"
      if params[:page].eql?(1) || params[:page].nil?
        @albums = @context.albums.published.paginate(:page => params[:page], :per_page => 17).to_a
        @featured_album = @albums.shift
      else
        @albums = @context.albums.published.paginate(:page => params[:page], :per_page => 16)
      end
    else
      @featured_album = Album.published.with_photos.featured.first || Album.published.with_photos.first
    end
  end
  
end
