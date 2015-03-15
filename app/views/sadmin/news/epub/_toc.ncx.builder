xml.instruct!
xml.declare! :DOCTYPE, :ncx, :PUBLIC, "-//NISO//DTD ncx 2005-1//EN", "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd"
xml.ncx :xmlns => "http://www.daisy.org/z3986/2005/ncx/", :version => "2005-1" do
  xml.head do
    xml.meta :name => "dtb:uid", :content => identifier
    xml.meta :name => "dtb:depth", :content => "1"
    xml.meta :name => "dtb:totalPageCount", :content => "0"
    xml.meta :name => "dtb:maxPageNumber", :content => "0"
  end

  xml.docTitle do
    if news.length > 1
      xml.text t('epub.title', :site_name => Settings.site_name, :locale => locale)
    else
      xml.text news.first.title
    end
  end

  xml.navMap do
    if news.length > 1
      xml.navPoint :id => "navpoint-0", :playOrder => 0 do
        xml.navLabel do
          xml.text t("epub.cover", :locale => locale)
        end
        xml.content :src => "news/cover.xhtml"
      end
      xml.navPoint :id => "navpoint-1", :playOrder => 1 do
        xml.navLabel do
          xml.text t('epub.toc', :locale => locale)
        end
        xml.content :src => "news/toc.xhtml"
      end
    end
    news.each_with_index do |news_item, i|
      play_order = i + 1 + (news.length > 1 ? 1 : 0)
      xml.navPoint :id => "navpoint-#{play_order}", :playOrder => play_order do
        xml.navLabel do
          xml.text "#{I18n.l(news_item.published_at.to_date, :locale => locale)}: #{news_item.send("title_#{locale}")}"
        end
        xml.content :src => "news/news#{news_item.id}.xhtml"
      end
    end
  end
end

