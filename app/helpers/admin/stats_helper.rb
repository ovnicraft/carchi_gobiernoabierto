module Admin::StatsHelper

  def short_url(url)
    url.length > 50 ? "#{url[0..49]}..." : url
  end

  def link_to_rss(rss)
    if m = rss.match(/\?u=(\d+)$/)
      return rss.sub(m[1], link_to(m[1], admin_user_path(:id => m[1])))
    elsif m = rss.match(/^\/e[sun]\/news\/(\d+).*\/comments\.rss$/)
      return rss.sub(m[1], link_to(m[1], news_path(:id => m[1])))
    else
      return rss
    end
  end

  def humanize_seconds secs
    if secs
      [[60, :s], [60, :m], [24, :h], [1000, :d]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i}#{name}"
        end
      }.compact.reverse[0..-2].join(':')
    end
  end
end
