xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => organization_news_index_url(:id => @organization.id, :format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link news_index_url
    
    for document in @documents
      xml.item do
        xml.title document.title
        xml.description document.pretty_body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
        xml.pubDate document.published_at.to_s(:rfc822)
        xml.link news_url(document)
        xml.guid news_url(document)
      end
    end
  end
end
