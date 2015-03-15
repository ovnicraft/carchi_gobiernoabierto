xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => debates_url(:format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link root_url
    
    for debate in @debates
      xml.item do
        xml.title debate.title
        xml.description debate.body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
        xml.pubDate debate.published_at.to_s(:rfc822)
        xml.link debate_url(debate)
        xml.guid debate_url(debate)
      end
    end
  end
end
