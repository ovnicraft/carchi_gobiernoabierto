# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')

namespace 'ogov' do
  namespace 'stats' do
    desc "Busca ficheros con nombre mpg, mpeg, mp4 y mp3"
    task :find_multimedia_files, :environment do
      exec "find -L #{Document::MULTIMEDIA_PATH} -iname \*.mpg -o -iname \*.mpeg -o -iname \*.mp4 -o -iname \*.mp3 >/tmp/irekia_fs.txt"
    end


    # Cuenta el numero total de ficheros mpg y mp3 en los directorios multimedia
    # Debería llamarse desde un cron job de la siguiente manera:
    # 7 * * * * sh /usr/app/ogov/batch_processes/update_file_system_stats.sh
    desc "Cargar datos iniciales"
    task :update_stats_fs do
      if File.exists?('/tmp/irekia_fs.txt')
        video_counter = `grep -i -E "(mpg|mpeg|mp4)$" /tmp/irekia_fs.txt |wc -l`
        puts "video_counter:" + video_counter
        mp3_counter = `grep -i mp3 /tmp/irekia_fs.txt |wc -l`
        puts "mp3_counter:" + mp3_counter
        stats_fs = Stats::FS.first
        stats_fs.update_attributes(:mpg => video_counter, :mp3 => mp3_counter)
      else
        puts "No existe el fichero"
      end
    end

    desc "Numero de noticias con solo texto"
    task :count_news_without_any_files do
      # list = Document.find_by_sql("SELECT * from documents where type='News' and published_at between '2011-01-01' and '2011-12-31' and cover_photo_file_name is null and not exists (select 1 from attachments where document_id=documents.id)")
      list = Document.find_by_sql("SELECT * from documents where type='News' and published_at between '2011-01-01' and '2011-12-31'")
      counters = {:sin_nada => 0, :con_algo => 0, :con_alta_calidad => 0, :mp3 => 0, :mpg => 0}
      list.each do |news|
        if news.has_professional_videos?('irekia') || news.has_photos?('irekia') || news.has_audios?('irekia')
          counters[:con_alta_calidad] += 1
        elsif !news.has_videos?('irekia') && !news.has_video?('irekia') && !news.has_cover_photo? && !news.has_files?
          counters[:sin_nada] += 1
        end

        counters[:mp3] += (news.audios('irekia')[:es] + news.audios('irekia')[:en] + news.audios('irekia')[:eu]).length
        counters[:mpg] += news.videos_mpg('irekia').length
        counters[:con_algo] = list.length - counters[:sin_nada]
      end
      puts "Total: #{counters.inspect}"
    end

    desc "Inicializa todos los contadores"
    task :recalculate_counters => [:environment, :recount_news_contents, :recount_proposal_contents, :recount_debate_contents, :recount_event_contents, :recount_video_contents]


    %w(News Proposal Debate Event Video ExternalComments::Item).each do |item_type|
      desc "Fill #{item_type} counters"
      task "recount_#{item_type.underscore.gsub('/', '_')}_contents".to_sym do
        item_type.constantize.order("id").each do |obj|
          puts "recounting #{item_type} #{obj.id}"
          counter = obj.stats_counter || obj.build_stats_counter
          counter.recount
          counter.save
          puts counter.errors.inspect if !counter.errors.empty?
        end
      end
    end

    # desc "Fills comments counters"
    # task :comments_counters do
    #   Comment.order("id").each do |comment|
    #     puts "comment on #{comment.commentable_type} #{comment.commentable_id}"
    #     comment.save
    #   end
    # end

    # desc "Fills arguments counters"
    # task :arguments_counters do
    #   Argument.order("id").each do |argument|
    #     puts "argument on #{argument.argumentable_type} #{argument.argumentable_id}"
    #     comment.save
    #   end
    # end

    # desc "Fills votes counters"
    # task :votes_counters do
    #   Vote.order("id").each do |vote|
    #     puts "vote on #{vote.votable_type} #{vote.votable_id}"
    #     vote.save
    #   end
    # end
  end
end
