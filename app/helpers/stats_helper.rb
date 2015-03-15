# encoding: UTF-8
module StatsHelper
  def view_counter_for(url)
    get_number_from_couchdb('counter/pagesp', url)
  end

  def flv_view_counter_for(url)
    get_number_from_couchdb('select/videosp', url)
  end

  def mpg_view_counter_for(url)
    get_number_from_couchdb('counter3/videoshqp', url)
  end

  def photo_view_counter_for(url)
    get_number_from_couchdb('counter3/photosp', url)
  end

  def streaming_view_counter(event)
    past_streaming_data = Stats::CouchDB.streaming_view_counter_for(event)

    ["Sesiones: <b>#{past_streaming_data[0]}</b>", "Pico de vistas simultáneas: <b>#{past_streaming_data[1]}</b>"].join(". ").html_safe
  end

  def get_number_from_couchdb(view, url)
    dbr = CouchRest.database(Rails.application.secrets['couchdb']['drb'])
    logger.info "Calculating stats for #{url}"
    today = Date.today
    begin
      ag = dbr.view view,
        {:limit => 1, :startkey => [url, 0, 0, 0], :endkey =>[url, today.year, today.month, today.day], :group_level => 1}
      res = ag['rows'].length > 0 ? ag['rows'][0]['value'] : 0
    rescue => err
      ActiveRecord::Base.logger.error "Could not get data from CouchDB: #{err}"
      res = "No DB connection"
    end
    return res
  end

end
