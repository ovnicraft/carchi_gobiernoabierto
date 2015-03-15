xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => news_index_url(:format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link root_url
    
    for news in @news
      xml.item do
        xml.title news.title
        xml.description news.pretty_body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
        xml.pubDate news.published_at.to_s(:rfc822)
        xml.enclosure render_rss_enclosure(news) unless news.cover_photo.url.eql?('/cover_photos/original/missing.png')
        xml.link news_url(news)
        xml.guid news_url(news)
      end
    end
  end
end
