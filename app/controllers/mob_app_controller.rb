class MobAppController < ApplicationController
  before_filter :get_context, :only => [:news, :events, :photos, :videos]
  layout false

  def news
    conditions = []

    if params[:o].present?
      last = News.find(params[:o])
      conditions = ["published_at < ?", last.published_at]
    end
    if @context.present?
      @news = @context.news.where(conditions).order('published_at DESC').limit(15)
    else
      @news = News.published.translated.listable.where(conditions).order('published_at DESC').limit(15)
    end

    render :action => "news.json"
  end

  def events
    if @context.present?
      @events = @context.events.where(["starts_at >= ? OR ends_at > ?", Date.today, Date.today]).limit(15)
    else
      @events = Event.published.translated.future(Time.zone.now - 1.day).limit(15)
    end

    render :action => "events.json"
  end

  def search
    if params[:page] && params[:page].to_i > 0
      @page=params[:page].to_i
      @from=(params[:page].to_i-1)*Elasticsearch::Base::ITEMS_PER_PAGE
    else
      @page=1
      @from=0
    end

    if params[:type].present?
      @type = params[:type]
    else
      @type = 'news'
    end

    @q = params[:q]
    if @page == 1
      criterio = Criterio.create(:title => "keyword: #{@q}", :ip => request.remote_ip, :iphone => true) 
    else
      criterio = Criterio.where(title: "keyword: #{@q}", ip: request.remote_ip, iphone: true).last
    end

    if @q.present?
      all_results=Elasticsearch::Base::do_elasticsearch_for_ios(criterio, @type, @from)
      @results = []
      @results = all_results['hits'] if all_results.present?
      render :action => "search.json"
    else
      redirect_to news_mob_app_url
    end
  end

  def tags
    @page=params[:page].present? ? params[:page].to_i : 1
    tags = ActsAsTaggableOn::Tag.find_by_sql(["SELECT * FROM tags WHERE (sanitized_name_es=? OR sanitized_name_eu=? OR sanitized_name_en=?)", params[:q], params[:q], params[:q]])
    tag_ids = tags.collect(&:id)
    conditions = "tag_id in (#{tag_ids.join(', ')})"
    @taggings = paginated_collection_of_tags_for(conditions, {:page => @page}, params[:type])
    render :action => "tags.json"
  end

  def photos
    conditions = []
    if params[:o].present?
      last = Photo.find(params[:o])
      conditions = ["photos.created_at <= ? AND photos.id < ?", last.created_at, last.id]
    end
    if params[:news_id].present?
      @document = News.find(params[:news_id])
      @photos = @document.album.photos if @document.album.present?
    elsif @context.present?
      @photos = @context.photos.where(conditions).order('created_at DESC').limit(48)
    else
      @photos = Photo.published.where(conditions).order("created_at DESC, id DESC").limit(48)
    end

    respond_to do |format|
      format.json {render :action => "photos.json"}
      format.floki do
        if ipad_app_request?
          render :action => "photos_ipad.json"
        elsif iphone4_app_request?
          render :action => "photos_ipad.json"
        else
          render :action => "photos.json"
        end
      end
    end
  end

  def videos
    conditions = []
    if params[:o].present?
      last = Video.find(params[:o])
      conditions = ["videos.published_at <= ? AND videos.id < ?", last.published_at, last.id]
    end
    if params[:news_id].present?
      @document = News.find(params[:news_id])
      @videos = @document.webtv_videos.published
    elsif @context.present?
      @videos = @context.videos.where(conditions).order('published_at DESC').limit(15)
    else
      @videos = Video.published.translated.where(conditions).order("published_at DESC, id DESC").limit(15)
    end
    respond_to do |format|
      format.json {render :action => "videos.json"}
      format.floki do
        if ipad_app_request?
          render :action => "videos_ipad.json"
        # elsif iphone4_app_request?
        #   render :action => "videos_ipad.json"
        else
          render :action => "videos.json"
        end
      end
    end

  end

  def areas
    get_areas
    render :action => "areas.json"
  end

  def area
    @area = Area.find(params[:area_id])
    if logged_in? && current_user.follows?(@area)
      @following = current_user.followings.find_by_followed_id(@area.id)
    end
    render :action => "area.json"
  end

  def politician
    @politician = Politician.find(params[:person_id])
    if logged_in? && current_user.follows?(@politician)
      @following = current_user.followings.find_by_followed_id(@politician.id)
    end
    render :action => "politician.json"
  end

  def team
    @area = Area.find(params[:area_id])
    @team = @area.users.approved
    render :action => 'team.json'
  end

  def show
    @v = params[:v] || params[:version]
    render :action => "show.json"
  end

  def v3
    render :action => "v3.json"
  end

  def v4
    render :action => "v4.json"
  end

  def root
    @all_proposals_citiz = Proposal.approved.published.count
    @all_proposals_gov = Debate.published.count
    @v = params[:v] || 1
    render :action => "root.#{@v}.json"
  end

  def appdata
    @v = params[:v] || params[:version]
    render :action => "appdata.#{@v}.json"
  end

  def about
    @pages = []
    ['legal_iphone', 'prop_int_iphone', 'about'].each do |page_type|
      begin
        @pages << Page.send(page_type)
      rescue
      end
    end
      # @pages = [Page.legal_iphone, Page.prop_int_iphone, Page.about].compact
    render :action => "about.json"
  end

  def proposals
    if params[:area_id]
      @area = Area.find(params[:area_id])
      @proposals = @area.approved_and_published_proposals.order("proposals.published_at DESC").limit(15)
    else
      @proposals = Proposal.approved.published.order("proposals.published_at DESC").limit(15)
    end
    render :action => "proposals.json"
  end

  def debates
    if params[:area_id]
      @area = Area.find(params[:area_id])
      @debates = @area.debates.published.translated.order("published_at DESC").limit(15)
    else
      @proposals = Debate.published.translated.order("published_at DESC").limit(15)
    end
    render :action => "debates.json"
  end

  def argazki
    extra = ""
    if params[:o].present?
      extra="&o=#{params[:o]}"
    end
    begin
      uri=(URI.parse("#{Rails.configuration.external_urls[:argazki_uri]}/api/photos?batch=42&size=m&more_info=true#{extra}"))
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = { 'Content-Type' => 'application/json'}
        response = http.send_request("GET", uri.request_uri, "", headers)
        logger.info "Argazki API Response: #{response.code} #{response.message}"
        @code=response.code
        @body=response.body
      end
    rescue => e
      logger.info "There were some problems connecting to Argazki #{Rails.configuration.external_urls[:argazki_uri]}. Please try later."
    end

    @photos=[]
    if @code.eql?('200')
      items = JSON.parse(@body)
      if items["status"].eql?(200)
        @photos = items["items"]
      else
        @error = true
      end
    end

    respond_to do |format|
      format.json {render :action => "argazki.json"}
      format.floki do
        if ipad_app_request? || iphone4_app_request?
          # aumentar la calidad de las imagenes
          render :action => "argazki_ipad.json"
        else
          render :action => "argazki.json"
        end
      end
    end
  end

  private
  # Devuelve los contenidos taggeados con las condiciones especificadas en <tt>conditions</tt>.
  # <tt>options</tt> son las opciones de paginación que se le pasa a WillPaginate
  def paginated_collection_of_tags_for(conditions, options = {}, model="all")
    options.reverse_merge!({:page => 1, :per_page => 10})
    page, per_page, total = options[:page], options[:per_page]
    pager = WillPaginate::Collection.new(page, per_page, total)
    options.merge!(:offset => pager.offset, :limit => per_page)

    #
    # No puedo usar "paginate" directamente porque si uso "distinct on" para que no me
    # aparezca la misma noticia varias veces, no puedo ordenar por fecha, asi que primero cojo todos,
    # los ordeno por fecha, y luego lo pagino.

    if model.eql?("all")
      result = ActsAsTaggableOn::Tagging
        .select("distinct ON (taggable_id) taggings.*, coalesce(documents.published_at, videos.published_at,
                    proposals.published_at, debates.published_at, photos.created_at, '2009-03-01') AS pub_at")
        .joins("LEFT OUTER JOIN documents ON (documents.id=taggings.taggable_id AND taggable_type='Document' AND published_at IS NOT NULL)
                   LEFT OUTER JOIN proposals ON (proposals.id=taggings.taggable_id AND taggable_type='Proposal')
                   LEFT OUTER JOIN debates ON (debates.id=taggings.taggable_id AND taggable_type='Debate')
                   LEFT OUTER JOIN photos ON (photos.id=taggings.taggable_id AND taggable_type='Photo')
                   LEFT OUTER JOIN videos ON (videos.id=taggings.taggable_id AND taggable_type='Video')")
        .where([conditions + " AND (CASE WHEN taggable_type IN ('Document', 'Video', 'Proposal') THEN COALESCE(documents.published_at, videos.published_at, proposals.published_at) IS NOT NULL ELSE true END)
          AND (CASE WHEN taggable_type IN ('Document', 'Proposal', 'Video', 'Debate')
               THEN COALESCE(documents.published_at, proposals.published_at, videos.published_at, debates.published_at) <= ?
               ELSE true END)
          AND (CASE WHEN taggable_type = 'Photo' THEN exists (select 1 from album_photos where album_photos.photo_id=photos.id) ELSE true END)", Time.zone.now])
        # :order => "pub_at desc"
    else
      case
      when document_subclasses.include?(model.constantize)
        result = ActsAsTaggableOn::Tagging
          .select("distinct ON (taggable_id) taggings.*, coalesce(documents.published_at, '2009-03-01') AS pub_at")
          .joins("INNER JOIN documents ON (documents.id=taggings.taggable_id AND taggable_type='Document' AND published_at IS NOT NULL)")
          .where(conditions + " AND documents.type='#{model}'")
          .where(["published_at IS NOT NULL AND published_at <=?", Time.zone.now])
      when model.eql?("Proposal")
        result = ActsAsTaggableOn::Tagging
          .select("distinct ON (taggable_id) taggings.*, coalesce(proposals.published_at, '2009-03-01') AS pub_at")
          .joins("INNER JOIN proposals ON (proposals.id=taggings.taggable_id AND taggable_type='Proposal')")
          .where(conditions)
          .where(["published_at IS NOT NULL AND published_at <=?", Time.zone.now])
      when model.eql?("Video")
        result = ActsAsTaggableOn::Tagging
          .select("distinct ON (taggable_id) taggings.*, coalesce(videos.published_at, '2009-03-01') AS pub_at")
          .joins("INNER JOIN videos ON (videos.id=taggings.taggable_id AND taggable_type='Video')")
          .where(conditions)
          .where(["published_at IS NOT NULL AND published_at <=?", Time.zone.now])
      when model.eql?("Photo")
        result = ActsAsTaggableOn::Tagging
          .select("distinct ON (taggable_id) taggings.*, coalesce(photos.created_at, '2009-03-01') AS pub_at")
          .joins("INNER JOIN photos ON (photos.id=taggings.taggable_id AND taggable_type='Photo')")
          .where(conditions + " AND exists (select 1 from album_photos where album_photos.photo_id=photos.id)")
      end
    end

    # res = result.sort {|a,b| Time.zone.parse(b.pub_at) <=> Time.zone.parse(a.pub_at)}
    res = result.sort {|a,b| b.pub_at <=> a.pub_at}
    # Esti
    # returning WillPaginate::Collection.new(page, per_page, result.length) do |pager|
    WillPaginate::Collection.new(page, per_page, result.length).tap do |pager|
      start_index = (page.to_i - 1) * per_page.to_i
      end_index = (page.to_i * per_page.to_i)-1
      pager.replace res[start_index..end_index] unless start_index >= result.length
    end
  end

end
