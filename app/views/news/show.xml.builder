xml.instruct!
xml.document do
  xml.language I18n.locale  
  xml.id @document.id
  xml.title @document.title
  xml.pubDate @document.published_at.to_s(:rfc822)
  xml.link news_url(@document)
  xml.guid @document.id  
  xml.speaker @document.speaker
  xml.organization do
    xml.title @document.organization.name
    xml.link @document.organization.gc_link
  end
  xml.description @document.pretty_body.gsub(/(\.\.\/)+\/uploads/, "/public/uploads")
    
  for tag in @document.tag_list
    xml.category tag
  end

  related_by_keywords = @document.get_related_news_by_keywords
  xml.related do
    related_by_keywords[0..7].each do |rel_document|
      if rel_document.published?
        xml.type rel_document.class.to_s
        xml.id rel_document.id
        xml.title rel_document.title
        xml.link url_for(:controller => controller_for(rel_document), :action => "show", :id => rel_document, :t => 1, :only_path => false)
      end
    end
  end
  
  
end
