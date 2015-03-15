# encoding: UTF-8
module StreamingsHelper

  def home_video_title(streaming_present, announced_streaming)
    title = link_to(t('videos.web_tv'), videos_path)
    if streaming_present
      title = t('events.streaming_live')
    elsif announced_streaming
      title = t('events.announced_streaming')
    end
    return title
  end

  def get_net_connection_url_for_streaming
      Rails.application.config.rtmp_server
  end
  
  def show_logo_for_streaming?(streaming)
    streaming.travelling? ? '1' : '0'
  end
  
end
