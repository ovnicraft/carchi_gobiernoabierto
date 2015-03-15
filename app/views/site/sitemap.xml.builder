xml.instruct!
xml.urlset :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc proposals_url
    xml.lastmod Proposal.published.last.published_at.xmlschema
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc debates_url
    xml.lastmod Debate.published.translated.current.last.published_at.xmlschema
    xml.changefreq "weekly"
  end

  xml.url do
    xml.loc news_index_url
    xml.lastmod News.published.translated.listable.last.published_at.xmlschema
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc events_url
    xml.lastmod Event.published.translated.last.published_at.xmlschema
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc albums_url
    xml.lastmod Album.published.with_photos.last.published_at.xmlschema
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc areas_url
    xml.lastmod Area.ordered.last.created_at.xmlschema
    xml.changefreq "monthly"
  end

  xml.url do
    xml.loc videos_url
    xml.lastmod Video.published.last.published_at.xmlschema
    xml.changefreq "daily"
  end

  xml.url do
    xml.loc new_person_url
    xml.lastmod Time.zone.parse('2013-08-28').xmlschema
    xml.changefreq "yearly"
  end

  xml.url do
    xml.loc login_url
    xml.lastmod Time.zone.parse('2013-08-28').xmlschema
    xml.changefreq "yearly"
  end

  xml.url do
    xml.loc page_site_url(:label => 'about')
    xml.lastmod Page.about.published_at.xmlschema
    xml.changefreq "yearly"
  end

end
