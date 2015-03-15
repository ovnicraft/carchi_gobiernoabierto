xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => events_url(:format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link root_url
    
    for event in @events
      xml.item do
        xml.title event.title
        xml.description event.pretty_body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
        xml.pubDate event.starts_at.to_s(:rfc822)
        xml.link event_url(event)
        xml.guid event_url(event)
      end
    end
  end
end
