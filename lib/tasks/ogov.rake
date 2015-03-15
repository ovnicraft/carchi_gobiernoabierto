require File.join(Rails.root, 'config', 'environment')
require File.join(Rails.root, 'lib', 'tasks', 'rake_utils')

gem 'twitter'
require 'twitter'

require File.join(Rails.root, 'lib', 'tasks', 'rake_utils')

namespace 'ogov' do

  # Recorre y envia la cola de alertas por enviar a periodistas
  # Debería llamarse desde un cron job de la siguiente manera:
  # 7 * * * * sh /usr/app/ogov/batch_processes/process_unsent_alerts_for_journalists.sh
  desc "Process unsent alerts for journalists"
  task :process_unsent_alerts_for_journalists do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Processing emails queue for journalists...")

      pending_alerts_for_future_events = EventAlert.for_journalists.unsent
        .joins(:event)
        .readonly(false)
        .where(["send_at <= ? AND ends_at >= ?", Time.zone.now, Time.zone.now])
        .order("created_at")

      pending_alerts_for_future_events.each do |alert|
        send_alert(alert, process_logger)
      end

      process_logger.info("#{Time.zone.now.to_s(:short)}: Finished processing emails queue for journalists. ")
      process_logger.info("===========")
    end
  end

  # Recorre y envia la cola de alertas por enviar a responsables de salas y operadores de streaming
  # Debería llamarse desde un cron job de la siguiente manera:
  # 7 * * * * sh /usr/app/ogov/batch_processes/process_unsent_alerts_for_staff.sh
  desc "Process unsent alerts for staff"
  task :process_unsent_alerts_for_staff do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Processing emails queue for staff....")

      pending_alerts_for_future_events = EventAlert.for_staff.unsent
        .joins(:event)
        .readonly(false)
        .where(["send_at <= ? AND ends_at >= ?", Time.zone.now, Time.zone.now])
        .order("created_at")

      pending_alerts_for_future_events.each do |alert|
        send_alert(alert, process_logger)
      end

      process_logger.info("#{Time.zone.now.to_s(:short)}: Finished processing emails queue for staff. ")
      process_logger.info("===========")
    end
  end

  def send_alert(alert, alert_logger)
    begin
      alert_logger.info("\tSending alert #{alert.id} from event #{alert.event_id} to #{alert.spammable_type} #{alert.spammable.email} that was programmed for #{alert.send_at.to_s(:short)}")
      if alert.spammable_type.eql?('Journalist')
        email = Notifier.journalist_event_alert(alert)
      else
        email = Notifier.staff_event_alert(alert)
      end
    rescue => err
      alert_logger.info("\talert #{alert.id}: There were some errors building email: #{err}")
    else
      begin
        email.deliver
      rescue Timeout::Error => err
        alert_logger.info "skipping #{alert.id} because of #{err}"
      rescue => err_type
        alert_logger.info("\tThere were some errors sending event alert: " + err_type.to_s)
      else
        alert.update_attributes(:sent_at => Time.zone.now)
        # If the event was deleted and there is noone else to tell about it, remove it from the database
        if alert.event.deleted? && alert.event.alerts.unsent.count == 0
          alert_logger.info("\tDeleting event #{alert.event.id}")
          alert.event.destroy
        end
      end
    end
    alert_logger.info("-----------")
  end


  # HT
  # # Recorre y envia la cola de tweets sobre nuevas noticias y eventos.
  # # Debería llamarse desde un cron job de la siguiente manera:
  # # 22 * * * * sh /usr/app/ogov/batch_processes/tweet_pending_issues.sh
  # desc "Tweet pending news and events"
  # task :tweet_pending_issues do |task_name|
  #   include Rails.application.routes.url_helpers

  #   RakeUtils.with_lock_file(task_name) do |process_logger|
  #     process_logger.info("#{Time.zone.now.to_s(:short)}: Processing tweets queue...")

  #     # twitter_accounts = YAML::load_file(File.join(Rails.root, 'config', 'twitter.yml'))
  #     twitter_accounts = {irekia_news: Rails.application.secrets['twitter_news'], irekia_agenda: Rails.application.secrets['twitter_agenda']}
  #     twitter_accounts.each do |account, account_info|

  #       # # Twitter gem version 0.7.9
  #       # oauth = Twitter::OAuth.new(account_info["token"], account_info["secret"])
  #       # oauth.authorize_from_access(account_info["atoken"], account_info["asecret"])
  #       # client = Twitter::Base.new(oauth)
  #       # Twitter gem version 1.1.2
  #       Twitter.configure do |config|
  #         config.consumer_key = account_info['token']
  #         config.consumer_secret = account_info['secret']
  #         config.oauth_token = account_info["atoken"]
  #         config.oauth_token_secret = account_info["asecret"]
  #       end

  #       DocumentTweet.pending(account).each do |tweet|
  #         if !tweet.document.published? || tweet.document.past?
  #           process_logger.info("\t Don't send tweet #{tweet.id} because document #{tweet.document_id} is quite old. Tweet is going to be deleted.")
  #           tweet.destroy
  #         else
  #           process_logger.info("\tSending tweet #{tweet.id} of #{tweet.document.class} #{tweet.document.id}
  #                                that was programmed for #{tweet.tweet_at.to_s(:short)}")
  #           begin
  #             if tweet.document.is_a?(News)
  #               url = url_for(:controller => "news", :action => "show", :id => tweet.document,
  #                 :locale => tweet.tweet_locale, :only_path => false, :host => ActionMailer::Base.default_url_options[:host])
  #               text = shorten("#{tweet.document.send("title_" + tweet.tweet_locale)}. ", 140 - 25) #25 because twitter shortens urls up to 25 chars
  #               text_and_url = "#{text} #{url}"
  #             else
  #               url = url_for(:controller => "events", :action => "show", :id => tweet.document,
  #                 :locale => tweet.tweet_locale, :only_path => false, :host => ActionMailer::Base.default_url_options[:host])
  #               event_date = I18n.localize(tweet.document.starts_at, :format => :short, :locale => tweet.tweet_locale)
  #               text = shorten("#{event_date}: #{tweet.document.send("title_" + tweet.tweet_locale)}. ", 140 - 25)
  #               text_and_url = "#{text} #{url}"
  #             end
  #             Twitter.update(text_and_url)
  #           rescue => err_type
  #             # if err_type.to_s.eql?("(403): Forbidden - Status is over 140 characters.")
  #             #   process_logger.info("\tWarning al mandar tweet #{tweet.id}: " + err_type)
  #             #   process_logger.info("\tAun asi lo marcamos como mandado")
  #             #   tweet.update_attributes(:tweeted_at => Time.zone.now)
  #             # else
  #               process_logger.info("\tError sending tweet #{tweet.id}: #{err_type}")
  #             # end
  #           else
  #             tweet.update_attributes(:tweeted_at => Time.zone.now)
  #           end
  #           process_logger.info("-----------")
  #           sleep 1
  #           break
  #         end
  #       end
  #     end
  #     process_logger.info("===========")
  #   end
  # end

  include PhotosHelper
  # comment this line to make politician_test work, only god knows why
  # include ActionView::Helpers::TextHelper

  # # Igual que la de photos_helper
  # def shorten(title, length=65)
  #   title.length > length ? "#{truncate(title, :length =>  length-1, :omission => "").sub(/[^\w]\w+$/, '')} ..." : title
  # end


  # Busca videos nuevos en las noticias del último mes, y los incluye en la WebTV.
  # Debería llamarse desde un cron job de la siguiente manera:
  # 36 * * * * sh /usr/app/ogov/batch_processes/include_new_videos_in_webtv.sh
  desc "Search new videos and include them in WebTV"
  task :include_new_videos_in_webtv do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Searching videos to include in WebTv")

      Document.select("id, multimedia_path, title_es, title_eu, title_en, published_at")
        .where("published_at IS NOT NULL AND coalesce(multimedia_dir, '') <> '' AND updated_at >=  now()-'1month'::interval").each do |doc|
          list_of_videos = Dir.glob(doc.full_multimedia_path + "*.flv") + Dir.glob(doc.full_multimedia_path + "solo_irekia/*.flv")
          list_of_videos.each do |doc_video|
            candidate = doc_video.sub(/^#{Document::MULTIMEDIA_PATH}/, '').sub(/(_es|_eu|_en)*.flv$/, '').sub(/^\//,'')
            process_logger.info "\tChecking if video #{doc_video} exists... (#{candidate})"
            unless Video.exists?(:video_path => candidate)
              # This will work because Document::MULTIMEDIA_PATH and Video::VIDEO_PATH are the same directory
              # otherwise we would have to copy the contents from one place to another
              visibility = lang_visibility(candidate)
              process_logger.info "\tCreating video for #{candidate}. Visible in #{visibility.select {|k, v| v}.collect {|a| a[0]}.join(', ')}"
              new_video = Video.new(:video_path => candidate, :title_es => doc.title_es,
                :title_eu => doc.title_eu.present? ? doc.title_eu : doc.title_es, :title_en => doc.title_en.present? ? doc.title_en : doc.title_es,
                :show_in_es => visibility[:es], :show_in_eu => visibility[:eu], :show_in_en => visibility[:en],
                :published_at => doc.published_at, :document_id => doc.id)
              new_video.tag_list = doc.tag_list.dup
              if new_video.save
                process_logger.info "\tVideo has been saved. "
              else
                process_logger.info "\tThere were some errors saving video #{new_video.errors.full_messages.join(', ')}. "
              end
            else
              process_logger.info "\tVideo already exists. "
            end
            process_logger.info "----------"
          end
      end
      process_logger.info "=========="
    end
  end

  # Comprueba si se han añadido idiomas a los videos de la WebTV.
  # Debería llamarse desde un cron job de la siguiente manera:
  # 43 * * * * sh /usr/app/ogov/batch_processes/check_webtv_video_languages.sh
  desc "Check language changes in WebTV videos of the last month"
  task :check_webtv_video_languages do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Looking for new languages in WebTV videos...")
      Video.where(["published_at BETWEEN ? AND ? ", Time.zone.now - 3.months, Time.zone.now]).each do |video|
        visibility = lang_visibility(video.video_path)

        #video.duration = video.duration_from_file if video.duration.blank?
        video.show_in_es = visibility[:es]
        video.show_in_eu = visibility[:eu]
        video.show_in_en = visibility[:en]
        video.save!
      end
      VideoSweeper.sweep
      # Video::LANGUAGES.each do |lang|
      #   Net::HTTP.get(URI.parse("http://192.168.146.24:8800/#{lang}/podcast.xml"))
      # end
    end
  end


  # Recorre todos los videos de la WebTV buscando videos "huerfanos", es decir, entradas en la base de datos
  # que no tienen videos por detras bien porque los han borrado o los han renombrado.
  # Cuando los encuentra, lo pone en estado "draft" para que no se muestren en la web y los revisen a mano
  # Debería llamarse desde un cron job de la siguiente manera:
  # 45 * * * * sh /usr/app/ogov/batch_processes/hide_orphan_videos_in_webtv.sh
  desc "Looks for webtv entries without video files"
  task :hide_orphan_videos_in_webtv do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Looking for videos to hide in WebTV...")

      drafted_videos = []
      Video.where(["published_at is not null AND published_at >=?", 6.months.ago]).order("id").each do |video|
        process_logger.info "\tChecking files for video #{video.id} (#{video.video_path}*.flv)"
        found_videos = Video.flv_videos_in_dir(video.video_path)
        if found_videos.length > 0
          process_logger.info "\t#{found_videos.length} videos were found. "
        else
          process_logger.info "\tNo files found. Video marked as draft."
          video.update_attributes(:published_at => nil)
          drafted_videos << video
        end
        process_logger.info "----------"
      end

      if drafted_videos.length > 0
        email = Notifier.orphan_videos_alert(drafted_videos)
        begin
          email.deliver
        rescue => err_type
          process_logger.info("\tThere were some errors sending orphan videos alert: " + err_type.to_s)
        else
          process_logger.info("\tOrphan videos alert sent.")
        end

      end

      process_logger.info "=========="
    end
  end


  def lang_visibility(path)
    {:es => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv"))),
     :eu => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv"))),
     :en => File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_en.flv")) || (!File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_es.flv")) && !File.exists?(File.join(Document::MULTIMEDIA_PATH, "#{path}_eu.flv")))}
  end


  desc "Importa las noticias de la aplicacion de Consejos de Gobierno"
  task :import_consejo_news do |task_name|
    # require 'rss'
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Importing consejo news...")
       sources = {"es" => "http://www.lehendakaritza.ejgv.euskadi.net/r48-acuerdos/es/v97aAcuerdosWar/V97AListaAcuerdosRSSServlet?idioma=c&tema=1&departamento=-1&accion=RSS&R01HNoPortal=true",
                  "eu" => "http://www.lehendakaritza.ejgv.euskadi.net/r48-acuerdos/es/v97aAcuerdosWar/V97AListaAcuerdosRSSServlet?idioma=e&tema=1&departamento=-1&accion=RSS&R01HNoPortal=true"}
      sources.each do |lang, source|
        xml_data = Net::HTTP.get_response(URI.parse(source)).body
        begin
          feed = REXML::Document.new(xml_data)
        rescue => err
          process_logger.info("There were some errors importing consejo news: #{err.inspect}")
        else
          feed.elements.each('rss/channel/item') do |feed_news|
            news = News.find_or_initialize_by(:consejo_news_id => feed_news.elements['guid'].text)
            process_logger.info("News: #{feed_news.elements['guid'].text}. It matches with #{news.id}")
            news.send("title_#{lang}=", "#{feed_news.elements['title'].text} (#{I18n.t('documents.consejo_de', :date => I18n.l(Date.parse(feed_news.elements['pubDate'].text), :locale => lang), :locale => lang)})")
            news_body = "<p class=\"r01Subtitular\">#{feed_news.elements['description'].text}</p>
            #{feed_news.elements['content'].text}
            <!-- <p>#{I18n.t('shared.source')}: <a href=\"#{feed_news.elements['link'].text}\">euskadi.net</a></p> -->"
            feed_news.elements.each("enclosure") do |enc|
              news_body << "<p><a href=\"#{enc.attribute("url")}\">#{I18n.t('site.mas_informacion')}</a></p>"
            end
            news.send("body_#{lang}=", news_body)
            news.updated_by = User.irekia_robot.id

            if news.new_record?
              process_logger.info("Is new.")
              news.published_at = feed_news.elements['pubDate'].text
              news.tag_list.add ["Acuerdos más relevantes del Consejo de Gobierno de #{I18n.localize(news.published_at.to_date, :locale => 'es')}", "Acuerdos más relevantes del Consejo de Gobierno"]
              sanitized_category = feed_news.elements['category'].text.tildes.sub('Departamento de ', '').downcase.gsub(/[^a-z]/, '')

              case sanitized_category
              when 'administracionpublicayjusticiaxleg'
                dep_name = 'administracionpublica'
              when "presidenciaxleg"
                dep_name = 'lehendakaritzaxleg'
              else
                dep_name = sanitized_category
              end

              department = Department.where(["regexp_replace(lower(tildes(name_es)), '[^a-z]', '', 'g') ~* ?", "^#{dep_name}.*"]).first

              news.organization_id = department.id if department
              news.created_by = User.irekia_robot.id
            end
            unless news.save
              process_logger.info("#{news.title} no ha podido importarse: #{news.errors.full_messages}")
            end
            process_logger.info("------------")
          end
          process_logger.info("============")
        end
      end
    end
  end


  # Busca fotos nuevas en las noticias del último mes, y los incluye en la Fototeca.
  # Debería llamarse desde un cron job de la siguiente manera:
  # 36 * * * * sh /usr/app/ogov/batch_processes/include_new_photos_in_gallery.sh
  desc "Search new photos and include them in Gallery"
  task :include_new_photos_in_gallery => :environment do |task_name|
    # include ActionController::UrlWriter
    # default_url_options[:host] = Rails.env.eql?("production") ? Notifier::SERVICEURL : "localhost:3000"
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Looking for new photos to include in gallery...")

      Document.select("id, multimedia_path, title_es, title_eu, title_en, published_at")
        .where("published_at IS NOT NULL AND coalesce(multimedia_dir, '') <> '' AND updated_at >= now()-'15days'::interval")
        .order("id DESC").each do |doc|
          process_logger.info "Looking fot photos for #{doc.id}..."
          list_of_photos = doc.photos
          if list_of_photos.length>0
            album = Album.find_or_initialize_by(:document_id => doc.id)
            if album.new_record?
              album.title_es = doc.title_es
              album.title_eu = doc.title_eu
              album.title_en = doc.title_en
              album.tag_list = doc.tag_list.dup
              album.created_at = doc.published_at
            end
            list_of_photos.each do |doc_photo|
              candidate = doc_photo.sub(/^#{Document::MULTIMEDIA_PATH}/, '')
              process_logger.info "\tChecking whether photo #{doc_photo} exists (#{candidate})..."
              unless Photo.exists?(:file_path => candidate)
                # This will work because Document::MULTIMEDIA_PATH and Video::PHOTO_PATH are the same directory
                # otherwise we would have to copy the contents from one place to another
                process_logger.info "\tCreating photo for #{candidate}..."
                new_photo = album.photos.build(:file_path => candidate, :dir_path => Pathname.new(candidate).dirname,
                  :title_es => doc.title_es,
                  :title_eu => doc.title_eu.present? ? doc.title_eu : doc.title_es,
                  :title_en => doc.title_en.present? ? doc.title_en : doc.title_es,
                  :created_at => doc.published_at,
                  :document_id => doc.id)
                new_photo.tag_list = doc.tag_list.dup

                # Must ensure that all sizes are created
                Tools::Multimedia::PHOTOS_SIZES.each do |size, geometry|
                  begin
                    IrekiaThumbnail.make(doc_photo, geometry, size)
                  rescue IrekiaThumbnailError => err
                    process_logger.error err
                  end
                end

                if new_photo.valid?
                  process_logger.info "\tPhoto is valid."
                else
                  process_logger.info "\tPhoto is not valid: #{new_photo.errors.full_messages.join(', ')}"
                end
              else
                process_logger.info "\tPhoto already exists."
              end
              process_logger.info "----------"
            end
            if album.save
              process_logger.info "\tAlbum has been saved."
            else
              process_logger.info "\tThere were some errors saving album #{album.errors.full_messages.join(', ')}. #{album.photos.collect {|p| p.errors.full_messages.join(', ')}.join("\n")}"
            end
          end
      end
      process_logger.info "=========="
    end
  end

  desc "Rebuilds thumbnails of photos of documents"
  task :build_photo_doc_thumbnails do  |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Rebuilding all thumbnails for documents...")
      Document.order("id desc").each do |doc|
        list_of_photos = Dir.glob("#{doc.full_multimedia_path}*.jpg") + Dir.glob("#{doc.full_multimedia_path}solo_irekia/*.jpg")
        list_of_photos.each do |doc_photo|
          build_thumbnails(doc_photo, Tools::Multimedia::PHOTOS_SIZES, process_logger)
        end
      end
      process_logger.info("#{Time.zone.now.to_s(:short)}: Finished")
      process_logger.info("========")
    end
  end

  desc "Rebuilds thumbnails of photos of gallery not belonging to news"
  task :build_photo_gallery_thumnails do |task_name|
    RakeUtils.with_lock_file(task_name) do |process_logger|
      process_logger.info("#{Time.zone.now.to_s(:short)}: Rebuilding all thumbnails for gallery photos...")
      Photo.where("document_id is null").order("id desc").each do |photo|
        build_thumbnails(File.join(Photo::PHOTOS_PATH, photo.file_path), Tools::Multimedia::PHOTOS_SIZES, process_logger)
      end
      process_logger.info("#{Time.zone.now.to_s(:short)}: Finished")
      process_logger.info("========")
    end
  end

  def build_thumbnails(photo, sizes, logger)
    logger.info "Rebuilding thumbnails for #{photo}"
    dirname, filename = Pathname.new(photo).split
    if File.exists?(photo)
      sizes.each do |size, geometry|
        thumbnail_file = "#{dirname}/#{size}/#{filename}"
        if File.exists?(thumbnail_file)
          logger.info("skipping #{dirname}/#{size}/#{filename} because it already exists")
        else
          logger.info("creating #{dirname}/#{size}/#{filename}")
          begin
            IrekiaThumbnail.make(photo, geometry, size)
          rescue IrekiaThumbnailError => err
            logger.error err
          end
        end
      end
    end
    logger.info("---------------")
  end

end
