# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')
require 'open-uri'

# require 'yaml'
# require 'yaml/encoding'
# require 'csv'

namespace 'external' do

  # desc "Importa las noticias en elastic search"
  # task :news_to_elasticsearch do
  #   News.published.translated.where(["published_at between ? and ? ", 2.days.ago, Date.today]).order("id DESC").each do |n|
  #     n.update_elasticsearch_related_server
  #     # puts n.id
  #   end
  # end
  #
  # desc "Cachea los relacionados"
  # task :cache_related do
  #   News.published.translated.order('updated_at DESC').limit(10).each do |doc|
  #     rd = []
  #     related_by_keywords = doc.get_related_news_by_keywords
  #     related_by_keywords[0..7].each do |rel_document|
  #       if !rel_document.draft? && rel_document.show_in_irekia?
  #         rd.push({:type => rel_document.class.to_s, :id => rel_document.id, :title => rel_document.title, :link => rel_document.is_a?(Link) ? document.url : nil, :controller => rel_document.is_a?(News) ? "documents" : rel_document.class.to_s.downcase.pluralize})
  #       end
  #     end
  #     doc.update_attribute(:cached_related, rd.to_json)
  #   end
  # end

 if Rails.application.secrets["twitter"]
  desc "Importa los tweets como comentarios"
  task :import_tweets_as_comments do

    twitter_credentials = Rails.application.secrets["twitter"]
    Twitter.configure do |config|
      config.consumer_key = twitter_credentials['token']
      config.consumer_secret = twitter_credentials['secret']
      config.oauth_token = twitter_credentials['atoken']
      config.oauth_token_secret = twitter_credentials['asecret']
    end

    import_logger = Logger.new(File.dirname(__FILE__) + "/../../log/import_tweets_as_comments.log")

    last_tweets = Twitter.search("irekia -from:irekia_news -from:irekia_agenda -from:irekia filter:links", :since_id => TwitterMention.last.tweet_id, :include_entities => true)
    import_logger.info "#{Time.zone.now}: Buscando a partir del tweet #{TwitterMention.last.tweet_id}"
    last_tweets.results.each do |tweet|
      import_logger.info "#{tweet.id}::#{tweet.created_at}::#{tweet.from_user}::#{tweet.text}"
      urls = tweet.urls.collect(&:url)
      import_logger.info "original url: #{urls.inspect}"
      decoded_urls = []
      urls.each do |url|
        begin
          open(url) do |resp|
            decoded_urls << resp.base_uri.to_s
            import_logger.info "decoded url: #{resp.base_uri.to_s}"
          end
        rescue => err
          import_logger.info "could not decode url: #{url.inspect}: #{err.inspect}"
        end
      end
      user_name = tweet.user.screen_name
      import_logger.info "tweeter: #{user_name}"

      TwitterMention.create :tweet_id => tweet.id,
        :user_name => user_name,
        :tweet_text => tweet.text,
        :tweet_entities => tweet.attrs[:entities].to_json,
        :tweet_decoded_urls => decoded_urls.to_json,
        :tweet_published_at => tweet.created_at

      decoded_urls.each do |decoded_url|
        # la url tiene que ser de un item (noticia, propuesta...)
        if decoded_url.match(/irekia.euskadi.net\/.+\d+/)
          import_logger.info "cita a irekia (#{decoded_url})"
          decoded_path = decoded_url.gsub(/http:\/\/([^\/]+)/, '')
          dummy, item_path, dummy2, item_querystring = decoded_path.match(/([^\?]+)(\?(.+))*/).to_a
          item_params = Rails.application.routes.recognize_path(item_path, :method => :get)
          # example: {:locale=>"es", :controller=>"documents", :id=>"5344-hospital-universitario-", :action=>"show"}

          # if %w(news posts documents events pages debates proposals).include?(item_params[:controller])
          #   item_type = item_params[:controller].singularize.camelize
          # else
          #   item_type = 'Document'
          # end

          item_type = item_params[:controller].singularize.camelize

          begin
            item = item_type.constantize.find(item_params[:id].to_i)
          rescue => err
            import_logger.info "Error al coger #{item_type} #{item_params[:id]}: #{err}"
            next
          end

          if item.respond_to?(:comments)
            # por ejemplo los eventos no tienen comentarios
            if item.comments.create :user => User.irekia_robot, :email => User.irekia_robot.email,
              :url => "http://twitter.com/#{user_name}", :name => "@#{user_name}",
              :body => "Comentario de <a href=\"http://twitter.com/#{user_name}/status/#{tweet.id}\" rel=\"external nofollow\">Twitter</a>:\n#{tweet.text}",
              :created_at => tweet.created_at, :updated_at => tweet.created_at
                import_logger.info "El tweet se ha importado en la #{item_type} #{item_params[:id]}"
            else
                import_logger.info "El tweet no se ha importado: #{item.errors.inspect}"
            end
          end
        else
          import_logger.info "no cita a irekia (#{decoded_url})"
        end
      end

      import_logger.info "----------"
    end
    import_logger.info "Fin de import\n======="
  end
 end

  desc "Import headlines from entzumena.irekia.euskadi.net"
  task :import_headlines => [:environment] do
    Area.import_headlines_from_albiste

    Area.all.each do |area|
      area.find_headlines_from_albiste
    end
  end

  desc "Import headlines keywords for areas"
  task :import_headline_keywords => [:environment] do
    file=CSV.open("#{Rails.root}/data/Entzumena-etiquetas-asignacion-areas-v2-20140228.csv", 'r', ';')
    file.shift
    file.each do |row|
      area = Area.find(:first, :conditions => {:name_es => row[0]})
      if area.present?
        headline_keywords = [row[1], row[2]].join().gsub(', ', ';')
        if area.update_attribute(:headline_keywords, headline_keywords)
          puts "Area #{area.name} headline keywords successfully updated"
        else
          puts "There were some errors updating area #{area.name}, #{area.errors.full_messages}"
        end
      else
        puts "Couldn't find area #{row[0]}"
      end
    end
  end

  # OpenURI decides that if redirects imply different protocols, it should not allow redirect.
  # We don't want this behaviour.
  # Source: http://www.megasolutions.net/ruby/Problem-with-open-uri-78351.aspx
  def OpenURI.redirectable?(uri1, uri2) # :nodoc:
    # This test is intended to forbid a redirection from http://... to file:///etc/passwd.
    # However this is ad hoc.  It should be extensible/configurable.
    uri1.scheme.downcase == uri2.scheme.downcase || (/\A(?:http|ftp|https)\z/i =~ uri1.scheme && /\A(?:http|ftp|https)\z/i =~ uri2.scheme)
  end

end
