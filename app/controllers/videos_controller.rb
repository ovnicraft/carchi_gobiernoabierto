# Controlador para la WebTV.
class VideosController < ApplicationController
  before_filter :get_context, :only => [:index]
  before_filter :get_criterio, :only => [:show]
  after_filter :track_clickthrough, :only => [:show]

  caches_page :podcast
  cache_sweeper :video_sweeper

  def index
    prepare_videos(@context, request.xhr?)

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => '/shared/list_items', :locals => {:items => @videos, :type => 'video'}, :layout => false
        else
          render
        end
      end
    end

  end

  def summary
    @featured_video = Video.published.featured
    @featured_albums = Album.published.with_photos.limit(2)
    # @featured_photo1 = featured_albums[0].cover_photo
    # @featured_photo2 = featured_albums[1].cover_photo
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
    end
  end

  def cat
    @categories = Video.categories
    @category = Category.find(params[:id])
    @title = @category.name
    @videos = @category.videos.paginate(:per_page => 12, :page  => params[:page] || 1).reorder("published_at DESC")
    respond_to do |format|
      format.html
    end
  end

  # Página de un video
  def show
    begin
      @video = Video.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if can_edit?("videos")
        @video = Video.find(params[:id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    @page_title_for_head = @video.title
    @title = t('videos.web_tv')

    # Comments
    @parent = @video
    @comments = @video.comments.approved.paginate :page => params[:page], :per_page => 25

    # , published_at DESC ")
    @related_videos = (Video.published.translated.tagged_with(@video.tag_list, :any => true, :order_by_matching_tag_count => true).limit(11)- [@video])[0..9]
    respond_to do |format|
      format.html
    end
  end

  def podcast
    @videos = Video.published.translated.limit(100).reorder("published_at DESC")
    render :action => "podcast.xml", :layout => false, :content_type => 'application/xml'
  end

  def closed_captions
    @videos = Video.published.with_closed_captions.paginate(:page => params[:page], :per_page => 12)
    @title = t('videos.closed_captions')
    render :action => 'cat'
  end

  private

  # Construye los breadcrumbs de cada acción de la WebTV
  def make_breadcrumbs
    if @context
      @breadcrumbs_info << [t('videos.title'), send("#{@context.class.to_s.downcase}_videos_path", @context)]
    else
      @breadcrumbs_info = [[t('videos.web_tv'), videos_path]]
      if @category
        @category.ancestors.reverse.each {|a| @breadcrumbs_info << [a.name, cat_videos_url(:id => a)]}
        @breadcrumbs_info << [@category.name, cat_videos_url(@category)]
      end
      if @video
        @breadcrumbs_info << [@video.title, video_path(@video)]
      end
      if params[:action].eql?('closed_captions')
        @breadcrumbs_info << [t('videos.closed_captions'), closed_captions_videos_path]
      end
    end
    @breadcrumbs_info
  end

  def prepare_videos(context, is_xhr)
    @title = t('videos.web_tv')
    if context
      @title << " #{t('shared.from_context', :name => context.public_name)}"
      if params[:page].eql?(1) || params[:page].nil?
        @videos = @context.videos.published.paginate(:page => params[:page], :per_page => 17).reorder('published_at DESC').to_a
        @featured_video = @videos.shift
      else
        @videos = @context.videos.published.paginate(:page => params[:page], :per_page => 16).reorder('published_at DESC')
      end
    else
      @featured_video = Video.published.featured
    end
  end

end
