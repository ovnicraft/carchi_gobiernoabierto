xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.atom(:link, :href => comments_url(:format => :rss), :rel => "self", :type => "application/rss+xml")
    xml.title @feed_title
    xml.description @feed_title
    xml.link root_url
    
    for comment in @comments
      parent = comment.commentable
      url = url_to_commentable(parent)
      
      xml.item do
        xml.title t("comments.feed_item_title", :author => show_comment_author_name(comment), :doc => parent.title)
        xml.description "#{t("comments.feed_item_body", :author => comment.author_name, :body => comment.body)}<br/><br/>#{t("comments.feed_sobre", :link => link_to(parent.title, url))}"
        xml.pubDate comment.created_at.to_s(:rfc822)
        xml.link url + "#comment-#{comment.id}"
        xml.guid url + "#comment-#{comment.id}"
      end
    end
  end
end
