xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => proposals_url(:format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link root_url
    
    for proposal in @proposals
      xml.item do
        xml.title proposal.title
        xml.description proposal.pretty_body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
        xml.pubDate proposal.published_at.to_s(:rfc822)
        xml.link proposal_url(proposal)
        xml.guid proposal_url(proposal)
      end
    end
  end
end
