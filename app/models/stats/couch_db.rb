# Clase para consulta los datos almacenados en CouchDB y mostrar los datos
# estadísticos en tiempo real
class Stats::CouchDB < ActiveRecord::Base
  # Devuelve los últimos 10 referers que han entrado en los logs en las últimas <tt>since_hours</tt> horas.
  def self.last_referers(since_hours)
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])

    moment = since_hours.hours.ago

    refs = Hash.new(0)
    begin
      ag = dbr.view('select/extref', { :descending => true,
                                       :limit => 100000,
                                       :endkey => [moment.year, moment.month, moment.day, moment.hour, 0] })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      refs["No hay conexión con la base de datos"] = 0
    else
      ag['rows'].each do |r|
        # p r['key'], r['value']
        referer =  r['value']
        isgoogle = Regexp.compile(/\.google\./)
        if !(/\.google\./ =~ referer) then
          # site = referer.gsub(/http:\/\/([^\/]+)\/.*$/, '\1')
          # puts referer, site
          refs[referer]+=1
        end
      end
    end
    referers = refs.sort {|a,b| b[1] <=> a[1]}[0..9]
  end

  # Devuelve las 10 últimas búsquedas que han entrado de Google.
  def self.last_googles
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])

    # moment = since_hours.hours.ago

    googles = []
    begin
      ag = dbr.view('select/extref', {:descending => true,
                                      :limit => 300,
                                      :endkey => [2010, 1, 1, 0, 0] })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      googles << "No hay conexion con la base de datos"
    else
      ag['rows'].each do |r|
         # pp r['key'], r['value']
         referer =  r['value']
         isgoogle = Regexp.compile(/\.google\./)
         if /\.google\./ =~ referer then
            sterms0 = referer.gsub(/.*?[&?]q=([^&]+)&?.*$/, '\1')
            sterms = CGI.unescape(sterms0)
            # puts referer
            googles << sterms
            # puts "---"
         end
      end
    end
    return googles[0..9]
  end

  # Devuelve las 10 páginas más visitadas en los últimos <tt>since_hours</tt> horas
  def self.top_pages(since_hours)
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])

    moment = since_hours.hours.ago

    # the most recent, back to :endkey
    totv = Hash.new(0)
    begin
      ag = dbr.view('counter/pages', { :descending => true,
                                   :limit => 10000,
                                   :endkey => [moment.year, moment.month, moment.day, moment.hour, ''],
                                   :group => true })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      totv["No hay conexión con la base de datos"] = ""
    else
      ag['rows'].each do |r|
         # pp r['key'], r['value']
         path = r['key'][4]
         ntimes = r['value']
         if !( (/news\/image/ =~ path) ||
               (/news\/photo/ =~ path) ||
               (/site\/change_locale/ =~ path) ||
               (/site\/search/ =~ path) ) then
           # pp path, ntimes
           totv[path] += ntimes
         end
      end
    end
    topp = totv.sort {|a,b| b[1] <=> a[1]}[0..9]
  end

  # Devuelve el número de diferentes IPs que se han conectado a servidor
  def self.last_ips_counter
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])

    moment = 5.minutes.ago

    ips = Hash.new(0)
    begin
      ag = dbr.view('counter/ips', { :descending => true,
                                  :limit => 10000,
                                  :group => true,
                                  :endkey => [moment.year, moment.month, moment.day, moment.hour, moment.min, "" ] })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
    else
      ag['rows'].each do |r|
        ip = r['key'][5]
        ips[ip] += 1
      end
    end
    return ips.size
  end

  def self.top_videos(since_days)
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])
    moment = since_days.days.ago

    totv = Hash.new(0)
    sum = 0
    begin
      ag = dbr.view('counter/videos', { :descending => true,
                                      :limit => 10000000,
                                      :endkey => [moment.year, moment.month, moment.day, 0, ''],
                                      :group => true })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      totv["No DB connection"] = 0
    else

      ag['rows'].each do |r|
         # pp r['key'], r['value']
         path = r['key'][4]
         ntimes = r['value']
         # pp path, ntimes
         totv[path] += ntimes
         sum += ntimes
      end
    end
    return {:videos => totv.sort {|a,b| b[1] <=> a[1]}[0..9], :sum => sum}
  end

  def self.top_rsss(since_days)
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])
    moment = since_days.days.ago

    sum = 0
    totv = Hash.new(0)

    begin
      ag = dbr.view('counter/rsss', { :descending => true,
                                      :limit => 10000000,
                                      :endkey => [moment.year, moment.month, moment.day, 0, ''],
                                      :group => true })
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      totv["No DB connection"] = 0
    else

      ag['rows'].each do |r|
        # pp r['key'], r['value']
        path = r['key'][4].gsub(/p=[0-9a-f]+&/, '')
        ntimes = r['value']
        # pp path, ntimes
        totv[path] += ntimes
        sum += ntimes
      end
    end
    return {:videos => totv.sort {|a,b| b[1] <=> a[1]}[0..14], :sum => sum}
  end

  # Devuelve un hash con las salas de streaming y el número de personas que lo están viendo.
  # Tanto si no aparece como si el contador está en 0, quiere decir que en esa sala no hay nada
  def self.streaming_watchers
    output = {}
    begin
      data = JSON.parse(`ssh -o ConnectTimeout=2 #{Rails.application.secrets['couchdb']['watchers_server']} ~/ww.rb`)
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
    else
      data.each do |code, counter|
        stream = StreamFlow.find_by_code(code)
        title = stream ? stream.title_es : code
        output[title] = counter
      end
    end
    return output
  end

  # Calcula el numero de personas que vio un streaming de un evento en su momento
  def self.streaming_view_counter_for(event)
    logger.info "Calculando streaming viewers para #{event.id}"
    qstream = event.stream_flow.code
    cfrom = event.starts_at - 30.minutes
    cto   = event.ends_at + 3.hour

    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb_wowza'])

    begin
      ag = dbr.view('inverse/dts', {:descending => false, :limit => 100000,
                                  :startkey   => [cfrom.year, cfrom.month, cfrom.day, cfrom.hour, cfrom.min, cfrom.sec],
                                  :endkey => [cto.year, cto.month, cto.day, cto.hour, cto.min, cto.sec]})
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      # puts "Could not get data from CouchDB: #{err}"
      return [0, "No DB Connection"]
    else
      honuser = Hash.new(0)
      stablecount = 0
      ips = Hash.new(0)
      sess = Hash.new(0)
      vmax = 0

      ag['rows'].each do |r|
          le = dbr.get(r['id'])
          stream = le['x-sname']

       if stream == qstream
          ips[le['c-client-id']] += 1
          sess[le['ip']] += 1
          event = le['x-event']
          stablecount += 1

          if event == 'play'
            honuser[stream] += 1
            # puts le['datetime'] + ' PLAY: ' + stream + " " + honuser[stream].to_s
            vmax = [honuser[stream], vmax].max
            stablecount = 0
          end

          if event == 'stop'
            honuser[stream] -= 1
            # puts le['datetime'] + ' STOP: ' + stream + " " + honuser[stream].to_s
            stablecount = 0
          end
          # puts "stablecount "+stablecount.to_s
          break if stablecount > 30

       end
      end
     end
    # # Devuelve el número total de sesiones y el máximo de viewers simultateos
    return [sess.keys.length, vmax]
    # return ag['rows'].length
  end
end
