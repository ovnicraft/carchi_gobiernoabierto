# Controlador para las estadísticas en tiempo real de últimas IPs,
# últimas búsquedas en Google, últimos referers y páginas más visitadas
class Admin::StatsController < Admin::BaseController
  def index
    @tab = 1
    @last_ips_counter = Stats::CouchDB.last_ips_counter
    @streaming_watchers = Stats::CouchDB.streaming_watchers
    @dep_id = 0
    @hours = params[:hours] ? params[:hours].to_i : 2

    @referers = Stats::CouchDB.last_referers(@hours)
    @googles = Stats::CouchDB.last_googles
    @top_pages = Stats::CouchDB.top_pages(@hours)
    @comments = Comment.select("commentable_id, commentable_type, count(id)")
      .where(["created_at between now()-?::interval and now()", "#{@hours} hours"])
      .group("commentable_id, commentable_type").order("count desc").limit(10)
  end

  def contents
    if params[:start] && params[:end]
      begin
        @start_date = Date.parse("#{params[:start][:year]}-#{params[:start][:month]}-#{params[:start][:day]}")
        @end_date = Date.parse("#{params[:end][:year]}-#{params[:end][:month]}-#{params[:end][:day]}")
        conditions = ["published_at BETWEEN ? AND ?", @start_date, @end_date]
        cover_photo_conditions = ["cover_photo_file_name is not null AND cover_photo_updated_at BETWEEN ? AND ?", @start_date, @end_date]
        @periodo = "#{I18n.localize(@start_date, :format => :long)} - #{I18n.localize(@end_date, :format => :long)}"
      rescue ArgumentError => err
        flash[:error] = "Las fechas elegidas no son correctas"
        redirect_to contents_admin_stats_path and return
      end
    else
      @end_date = Date.today
      cover_photo_conditions = "cover_photo_file_name is not null"
    end

    @tab = 3
    @pages_counter = Page.where(conditions).count
    @comments_counter = Comment.where(created_at_conditions).count
    @photos_counter = Photo.where(created_at_conditions).count
    @cover_photos_counter = Document.where(cover_photo_conditions).count
    @webtv_video_counter = Video.where(conditions).count
    @attachment_counter = Attachment.where(created_at_conditions).count
    @escucha_counter = {:total => Headline.where(created_at_conditions).count, :published => Headline.where(conditions).count}

    # Valoracion de relacionados
    @top_voters = RecommendationRating.select("count(recommendation_ratings.id) AS counter, user_id")
      .group("user_id").joins(:user).limit(5).order("counter desc")
  end

  def news
    counters
    top_rsss = Stats::CouchDB.top_rsss(@actual_days)
    @top_rsss = top_rsss[:videos]
    @rsss_sum = top_rsss[:sum]
  end

  def proposal
    counters
  end

  def event
    counters
    @shared_events_counter = Event.where(date_conditions).count
    @events_with_streaming = Event.with_streaming.where(date_conditions).count

    @events_with_streaming_in_sedes = Event.with_streaming.where(date_conditions).where("send_alerts = 'f'").joins(:stream_flow).count
    @events_with_streaming_itinerante = Event.with_streaming.where(date_conditions).where("send_alerts = 'f'").joins(:stream_flow).count
  end

  def video
    counters
    top_videos = Stats::CouchDB.top_videos(@actual_days)
    @top_videos = top_videos[:videos]
    @videos_sum = top_videos[:sum]
    # FS
    @videos_mpg = Stats::FS.mpg
    @audios_mp3 = Stats::FS.mp3

  end

  def debate
    counters
  end

  def external_comments
    counters
  end

  def bulletin
    if params[:start] && params[:end]
      @start_date = Date.parse("#{params[:start][:year]}-#{params[:start][:month]}-#{params[:start][:day]}")
      @end_date = Date.parse("#{params[:end][:year]}-#{params[:end][:month]}-#{params[:end][:day]}")
      @periodo = "#{I18n.localize(@start_date, :format => :long)} - #{I18n.localize(@end_date, :format => :long)}"

      @bulletin_counter = Bulletin.sent.where(["sent_at BETWEEN ? AND ?", @start_date, @end_date]).count
      @opening_counter = Bulletin.sent.reduce(0) {|sum, b| sum = sum + b.openings.where(["sent_at BETWEEN ? AND ?", @start_date, @end_date]).count}
      @click_counter = Bulletin.sent.reduce(0) {|sum, b| sum = sum + b.clicks_from.where(["sent_at BETWEEN ? AND ?", @start_date, @end_date]).count}
    else
      @bulletin_counter = Bulletin.sent.count
      @opening_counter = Bulletin.sent.reduce(0) {|sum, b| sum = sum + b.openings.count}
      @click_counter = Bulletin.sent.reduce(0) {|sum, b| sum = sum + b.clicks_from.count}
    end
  end

  private

  def set_current_tab
    @current_tab = :stats
  end

  def build_couchdb_days
    if params[:couchdb_start] && params[:couchdb_end]
      begin
        @couchdb_start_date = Date.parse("#{params[:couchdb_start][:year]}-#{params[:couchdb_start][:month]}-#{params[:couchdb_start][:day]}")
        @couchdb_end_date = Date.parse("#{params[:couchdb_end][:year]}-#{params[:couchdb_end][:month]}-#{params[:couchdb_end][:day]}")
      rescue ArgumentError => err
        flash[:error] = "Las fechas elegidas no son correctas"
        redirect_to contents_admin_stats_path and return
      end
    else
      @couchdb_start_date = 1.day.ago.to_date
      @couchdb_end_date = Date.today
    end
    @actual_days = (@couchdb_end_date-@couchdb_start_date).to_i
    if @actual_days > 275
      flash[:notice] = "Sólo se puede consultar un máximo de 9 meses atrás"
      redirect_to contents_admin_stats_path and return
    end
  end

  def counters
    @for = action_name

    @counters_finder = Stats::Counter.where(["countable_subtype=:countable_subtype ", {countable_subtype: @for.camelize}])

    if params[:start] && params[:end]
      @start_date = Date.parse("#{params[:start][:year]}-#{params[:start][:month]}-#{params[:start][:day]}")
      @end_date = Date.parse("#{params[:end][:year]}-#{params[:end][:month]}-#{params[:end][:day]}")
      @periodo = "#{I18n.localize(@start_date, :format => :long)} - #{I18n.localize(@end_date, :format => :long)}"

      @counters_finder = @counters_finder.where(date_conditions)
    else
      @end_date = Date.today
    end

    build_couchdb_days
  end

  def date_conditions
    if params[:start] && params[:end]
      dc = ["published_at BETWEEN ? AND ?", @start_date, @end_date]
    else
      dc = nil
    end
    dc
  end

  def created_at_conditions
    if params[:start] && params[:end]
      cc = ["created_at BETWEEN ? AND ?", @start_date, @end_date]
    else
      cc = nil
    end
    cc
  end
end
