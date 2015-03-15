# API de Irekia
class IrekiaApiController < ApplicationController
  include SiteHelper
  include DocumentsHelper
  include SiteHelper
  
  def tags
    @tags = []
    ActsAsTaggableOn::Tag.all.each do |tag|
      h = {:id => tag.id, :name_es => tag.name_es, :name_eu => tag.name_eu, :name_en => tag.name_en, :kind => tag.kind, :gc_link => tag.gc_link}
      @tags.push h.to_json
    end
    respond_to :json
  end
  
  def photos
    get_document()
    @photos = []
    
    news_photo_sizes = ['n70', 'n320', 'n770']
    
    if @document.cover_photo?
      h = {:original => cover_photo_full_url(@document.cover_photo.url)}
      news_photo_sizes.each do |size|
        h[size] = cover_photo_full_url(@document.cover_photo.url(size)) 
      end
      @photos.push h.to_json
    end
    
    @document.photos.each do |photo|
      h = {:original => url_for_photo(photo)}
      news_photo_sizes.each do |size|
        h[size] = url_for_photo(document_img_tag(photo, size))
      end
      @photos.push h.to_json
    end
    respond_to :json
  end

  def videos
    get_document()
    @videos = {:list => {:es => [], :eu => [], :en => []}, 
              :featured => {:es => nil, :eu => nil, :en => nil}, 
              :mpg => {:es => [], :eu => [], :en => []}}
    
    @document.videos.each do |key, values|
      case key
        when :list
          values.each do |lang, v_list|
            v_list.each do |v|
              @videos[key][lang].push(get_video_data(v))
            end  if v_list.present?
          end
        when :featured
          values.each do |lang, v|
            @videos[key][lang] = get_video_data(v) if v.present?
          end
        else
          # para los vídeos mpeg sólo mostramos el path
          values.each do |lang, v_list|
            v_list.each do |v|
              @videos[key][lang].push(Document::MULTIMEDIA_URL + v)
            end if v_list.present?
          end
      end
    end
    respond_to :json
  end

private

  def get_document
    begin
      @document = News.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      if can_edit?("news")
        @document = News.find(params[:id])
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end    
  
  def cover_photo_full_url(path)
     request.protocol + request.host_with_port + path
  end
  
  def get_video_data(v)
    size = '320x240'
    width, height = size.split('x')
    
    video_info = flv_video_info(v)
    height = (width.to_i*9/16).to_i if video_info[:display_format].eql?('169')
    data = {:html5src => html5_video_for(video_info[:video]),
            :poster => video_info[:preview_img],
            :title => video_info[:title],
            :duration => video_info[:duration] || '',
            :embed => render_to_string(:partial => "/shared/code_to_embed_video.html", 
                                       :locals => {:video_info => video_info, 
                                                   :height => height}).gsub(/\n/, '')}
    data
  end
end
