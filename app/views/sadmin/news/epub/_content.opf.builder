xml.instruct!
xml.package :xmlns => "http://www.idpf.org/2007/opf", "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/", "unique-identifier".to_sym => "bookid", :version => "2.0" do
  xml.metadata do
    xml.meta :name => "generator", :content => Settings.site_name
    if news.length > 1
      xml.tag!("dc:title", t('epub.title', :site_name => Settings.site_name, :locale => locale))
    else
      xml.tag!("dc:title", news.first.title)
    end
    xml.tag!("dc:creator", t('epub.creator', :publisher_name => Settings.publisher[:name], :publisher_address => Settings.publisher[:address], :locale => locale))
    xml.tag!("dc:subject")
    xml.tag!("dc:description")
    xml.tag!("dc:publisher", Settings.publisher[:name])
    xml.tag!("dc:date", I18n.l(Date.today, :locale => locale))
    xml.tag!("dc:source")
    xml.tag!("dc:relation")
    xml.tag!("dc:coverage")
    xml.tag!("dc:rights", t('epub.rights', :publisher_name => Settings.publisher[:name], :locale => locale))
    xml.tag!("dc:identifier", identifier, :id => "bookid")
    xml.tag!("dc:language", "es")
    xml.meta :name => "cover", :content => "irekia-cover-jpg"
  end

  xml.manifest do
    xml.item :id => "ncx", :href => "toc.ncx", "media-type".to_sym => "application/x-dtbncx+xml"
    if news.length > 1
      xml.item :id => "cover", :href => "news/cover.xhtml", "media-type".to_sym => "application/xhtml+xml"
      xml.item :id => "toc", :href => "news/toc.xhtml", "media-type".to_sym => "application/xhtml+xml"
    end

    news.each_with_index do |news_item, i|
      xml.item :id => "news#{news_item.id}", :href => "news/news#{news_item.id}.xhtml", "media-type".to_sym => "application/xhtml+xml"
      if news_item.has_cover_photo?
        xml.item :id => "news#{news_item.id}-jpg", :href => "images/news#{news_item.id}.jpg", "media-type".to_sym => "image/jpeg"
      end
    end

    xml.item :id => "css", :href => "template.css", "media-type".to_sym => "text/css"
    xml.item :id => "irekia-cover-jpg", :href => "images/irekia-cover.jpg", "media-type".to_sym => "image/png"
  end

  xml.spine :toc => "ncx" do
    if news.length > 1
      xml.itemref :idref => "cover"
      xml.itemref :idref => "toc"
    end

    news.each_with_index do |news_item, i|
      xml.itemref :idref => "news#{news_item.id}"
    end
  end

  # For kindlegen .mobi generator
  xml.guide do
    xml.reference :href => "news/toc.xhtml", :type => "toc", :title => t('epub.toc')
  end
end

