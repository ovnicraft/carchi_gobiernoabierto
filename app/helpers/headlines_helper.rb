module HeadlinesHelper

  def link_to_headline_tweets(headline)
    link_to(no_tweets_text(headline.tweets), headline_entzumena_url(headline), :rel => :external)
  end

  def headline_entzumena_url(headline)
    if Rails.configuration.external_urls[:albiste_uri]
      File.join(Rails.configuration.external_urls[:albiste_uri], I18n.locale.to_s, "headlines", headline.source_item_id)
    else
      ""
    end
  end

  def no_tweets_text(no_tweets)
    "<span class='rel_link'>#{I18n.t('headlines.actividad_twitter', :count => "<span class='number'>#{no_tweets}</span>")}</span>".html_safe
  end

end
