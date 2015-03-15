class Sadmin::SubtitlesController < Sadmin::BaseController
  before_filter :manage_subtitles_permission_required
  before_filter :get_news
  
  def index
    get_videos
    @document = @news
    @title = @news.title
  end

  def show
  end

  private
  
  def get_news
    # Guardamos la noticia en @document para aprovechar los helpers relacionados con vídeos que esperan esta variable
    @news = News.find(params[:news_id])
  end
  
  # Determina el tab del menú que está activo
  def set_current_tab    
    @current_tab = :news
  end
  
  def get_videos
    featured = @news.videos[:featured]
    list = @news.videos[:list]
    # Juntamos el video destacado de la noticia con los demás vídeos
    @videos = {:es => ([featured[:es]] + list[:es]).compact, 
               :eu => ([featured[:eu]] + list[:eu]).compact, 
               :en => ([featured[:en]] + list[:en]).compact}
    # Quitamos de la lista de vídeos por idiomas los que ya están en la lista de castellano
    @videos[:eu] = @videos[:eu] - @videos[:es]
    @videos[:en] = @videos[:en] - @videos[:es]      
  end
end
