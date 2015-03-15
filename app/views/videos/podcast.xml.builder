author = "#{Settings.publisher[:name]} #{Settings.site_name}"
xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
xml.rss(:version => "2.0", 'xmlns:itunes' => "http://www.itunes.com/dtds/podcast-1.0.dtd") do
  xml.channel do
    xml.title I18n.t('site.title', :site_name => Settings.site_name, :publisher_name => Settings.publisher[:name])
    xml.link videos_url
    xml.language "#{I18n.locale}-es"
    xml.copyright I18n.t('videos.podcast_copyright', :publisher_name => Settings.publisher[:name])
    xml.itunes :subtitle, Settings.publisher[:name]
    xml.itunes :author, author
    xml.itunes :summary, I18n.t('videos.podcast_summary', :site_name => Settings.site_name, :publisher_name => Settings.publisher[:name])
    xml.itunes :keywords, "#{Settings.publisher[:name]}, Gobierno abierto, Open Government, transparencia, participacion"
    xml.description I18n.t('videos.podcast_summary', :site_name => Settings.site_name, :publisher_name => Settings.publisher[:name])
    xml.itunes :owner do
      xml.itunes :name, author
      xml.itunes :email, Settings.email_addresses[:contact]
    end
    xml.itunes :image, :href => "http://www.irekia.euskadi.net/images/logo_podcast.jpg"
    xml.itunes :category, :text => "Government & Organizations" do
      xml.itunes :category, :text => "Regional"
    end
    xml.itunes :category, :text => "News & Politics"
    xml.itunes :explicit, "clean"

    @videos.each do |video|
     if video.featured_video
      video_path = File.join(Video::VIDEO_PATH, html5_video_for(video.featured_video))
      video_url = File.join(Video::VIDEO_URL, html5_video_for(video.featured_video))
      if File.exists?(video_path)
        xml.item do
          xml.title video.title
          xml.itunes :subtitle, subtitle_for_podcast(video)
          xml.itunes :summary, summary_for_podcast(video)
          xml.itunes :author, author
          xml.enclosure :url => video_url, :type => "video/x-m4v", :length => File.size(video_path)
          xml.guid video_url
          xml.pubDate video.published_at.to_s(:rfc822)
          xml.itunes :duration, video.duration
          xml.itunes :keywords, video.tags.all_public.collect {|t| t.name}.join(', ')
          xml.itunes :explicit, "clean"
        end
      end
     end
    end
  end
end
