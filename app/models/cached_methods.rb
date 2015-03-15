require 'rake_keywords'
require 'json'

module CachedMethods

  def self.included(base)
    base.has_one :cached_key, :as => :cacheable, :dependent => :destroy
    base.after_save :save_cached_keys
    base.after_save :update_elasticsearch_related_server
    base.after_destroy :delete_from_elasticsearch_related_server
  end

  CURRENT_TERM_START_DATE = Date.new(2012,12,17)

  def save_cached_keys
    if self.title_es.present? && self.title_es.tildes.strip_html.present? && self.body_es.present? && self.body_es.tildes.strip_html.present?
      tit = self.title_es.tildes.strip_html.gsub(/<\/?[^>+]*>/, "").gsub(/[\+\-\*\[\]\\=\?]/,'').gsub(/[\r|\n\(\)\-\'\"]/, " ").gsub(/([0-9]+)\.([0-9]+)/,'\1\2')
      bod = self.body_es.tildes.strip_html.gsub(/<\/?[^>+\+\-]*>/, "").gsub(/[\+\-\*\[\]\\=\?]/,'').gsub(/[\r|\n\(\)\-\'\"]/, " ").gsub(/([0-9]+)\.([0-9]+)/,'\1\2')[0, 5000]

      # Se aplica el algoritmo para cada una de las noticias y se guardan en formato json
      cached_keywords = self.cached_key || self.build_cached_key
      begin
        rk = RakeKeyword.new(bod)
        r = rk.keywords()

        rakeq = tit
        inir = r[0][1]
        r.each do |sk|
          if (sk[1] >= inir/3.5) && (rakeq.length < 250)
            rakeq = rakeq + " " + sk[0]
          end
        end
        rh = {}
        r.each {|k, v| rh[k]=v}
        rakeq_json = rh.to_json

        cached_keywords.rake_es = rakeq_json
        if (cached_keywords.changed? ? cached_keywords.save : cached_keywords.touch)
          logger.info "CachedKeys saved for #{self.class.name} #{self.id}"
        else
          logger.info "Error saving cachedKeys for #{self.class.name} #{self.id} #{self.errors.to_sentence}"
        end
      rescue => err
        logger.info "#{self.class.name} #{self.id} could not be processed: #{err}"
      end
    end
  end

  def text_with_selected_keywords
    cached_keywords = self.cached_key
    if cached_keywords.blank? || cached_keywords.new_record? || (self.is_a?(News) && (self.updated_at > cached_keywords.updated_at))
      logger.info "Recalculamos las keywords de #{self.class} #{self.id}"
      self.save_cached_keys
    end
    text = self.title.tildes.strip_html.escape_for_elasticsearch.gsub(/<\/?[^>+]*>/, "").gsub(/[\+\-\*\[\]\\=\?]/,'').gsub(/[\r|\n\(\)\-\'\"]/, " ").gsub(/([0-9]+)\.([0-9]+)/,'\1\2').downcase
    self.reload
    cached_keys = self.cached_key
    if cached_keys && cached_keys.rake_es.present?
      keywords_with_rating = JSON.parse(cached_keys.rake_es).sort{|a,b| b[1] <=> a[1]}
      top_rating= keywords_with_rating[0][1]
      keywords_with_rating.each do |keyword, rating|
        if (rating >= top_rating/3.5) && text.length < 250
          text << " #{keyword}"
        end
      end
    else
      text = ""
    end
    text.escape_for_elasticsearch
  end

  def get_related_news_by_keywords
    query=self.text_with_selected_keywords
    # filter out news from other terms
    if self.is_a?(News) && self.published_at.present? && self.published_at > CURRENT_TERM_START_DATE
      full_query={'size' => 12, 'from' => 0,
        'query' => {
          'filtered' => {'filter' => {'and' => [{"range" => {"published_at" => { 'from' => CURRENT_TERM_START_DATE, 'to' => Time.zone.now.strftime_search}}}]},
          'query' => {'query_string' => {'query' => "#{query}" }} }} }
    else
      full_query={'size' => 12, 'from' => 0,
        'query' => { 'query_string' => {'query' => "#{query}" } } }
    end

    self.get_related_by_keywords(full_query, 'news')
  end

  def get_related_orders_by_keywords
    query=self.text_with_selected_keywords
    full_query={'size' => 12, 'from' => 0,
        'query' => {
          'filtered' => {'filter' => {'and' => [{"range"=>{"published_at" => Elasticsearch::Base::DATE_RANGES['4y']}}]},
          'query' => {'query_string' => {'query' => "#{query}" }} }} }

    self.get_related_by_keywords(full_query, 'orders')
  end

  def get_related_by_keywords(full_query, target='news')
    begin
      uri=(URI.parse("#{Elasticsearch::Base::RELATED_URI}/#{target}/_search?pretty=true"))
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = { 'Content-Type' => 'application/json'}
        data = full_query.to_json
        response = http.send_request("GET", uri.request_uri, data, headers)
        #puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
        @code=response.code
        @body=response.body
      end
    rescue => e
      Rails.logger.info "ERROR getting related by keywords #{self.class.name} #{self.id}: #{e}"
      # flash[:error]=t('site.busqueda_no_disponible')
      # return []
    end
    results=Array.new

    # Include items with rating > 2 from Database (no keywords, no elasticsearch)
    self.recommendation_ratings_added_and_grouped_for(target).select{|a| a.rating > 2}.each do |item|
      if item.target.class.name.tableize.eql?(target)
        item.target.total_rating = item.rating.to_i
        results.insert(0, item.target)
      end
    end

    items_hash = {}
    if @code.eql?('200')
      JSON.parse(@body)['hits']['hits'].each do |result|
        if items_hash[result['_type']].nil?
          items_hash[result['_type']] = [[result["_id"], result["_score"]]]
        else
          items_hash[result['_type']] << [result["_id"], result["_score"]]
        end
      end
      # Dismiss items with rating < -2
      items_hash.each_pair do |key, values|
        ids = values.map{|a| a[0].to_i}
        case key
        when 'news'
          items = key.classify.constantize.where({:id => ids}).select("id, title_es, title_eu, title_en, published_at, comments_count, multimedia_path, cover_photo_file_name, consejo_news_id").order(ids.reverse.map{|a| "ID=#{a}"}.join(','))
        when 'orders'
          items = key.classify.constantize.where({:id => ids}).select("id, titulo_es, titulo_eu, fecha_bol, no_orden").order(ids.reverse.map{|a| "ID=#{a}"}.join(','))
        end
        to_delete = []
        items.each_with_index do |item, i|
          related_rating=self.recommendation_ratings_added_for(item)
          if (related_rating.rating.present? && related_rating.rating <= -2) || values[i][1] <= item.class.related_coefficient
            to_delete << item.id
          else related_rating.rating.present?
            item.total_rating = related_rating.rating.to_i
            item.score = values[i][1]
          end
          # item.explanation = values[i][2]
        end
        items.to_a.delete_if {|a| to_delete.include?(a.id)}
        results.push(items) if items.present? && self.published?
      end
    end
    return results.flatten.uniq - [self]
  end

  def recommendation_ratings_added_for(target)
    RecommendationRating.where(:source_id => self.id, :source_type => self.class.base_class.name, :target_type => target.class.base_class.name, :target_id => target.id).select("sum(rating) as rating").order("rating").first
  end

  def recommendation_ratings_added_and_grouped_for(target)
    target_type = target.eql?('news') ? 'Document' : 'Order'
    RecommendationRating.where(:source_id => self.id, :source_type => self.class.base_class.name, :target_type => target_type).select("sum(rating) as rating, target_id, target_type, max(updated_at) as updated_at").group("target_id, target_type").order("rating, updated_at")
  end

  def fields_for_search_related
    h= {
      "title_es" => self.title_es.to_s.tildes,
      "title_eu" => self.title_eu.to_s.tildes,
      "body_es" => self.body_es.to_s.tildes.strip_html,
      "body_eu" => self.body_eu.to_s.tildes.strip_html,
    }
    if self.is_a?(News)
      h.merge!({
        "tags_es" => self.tags.map{|a| a.name_es.tildes}.join(','),
        "tags_eu" => self.tags.map{|a| a.name_eu.tildes}.join(','),
        "department_es" => (self.department.name_es||'').tildes,
        "department_eu" => (self.department.name_eu||'').tildes,
        "asiste_es" => (self.speaker_es || '').tildes,
        "asiste_eu" => (self.speaker_eu || '').tildes,
        "published_at" => self.published_at.strftime("%Y-%m-%dT%H:%M:%S")
      })
    elsif self.is_a?(Order)
      h.merge!({
        "department_es" => self.dept_es.tildes,
        "department_eu" => self.dept_eu.tildes,
        "published_at" => self.fecha_bol.strftime("%Y-%m-%dT%H:%M:%S")
      })
      h.merge!({"materias_es" => self.materias_es.split(';').join(', ').tildes}) if self.materias_es.present?
      h.merge!({"materias_eu" => self.materias_eu.split(';').join(', ').tildes}) if self.materias_eu.present?
    end
    h
  end

  def update_elasticsearch_related_server
    if self.changed.include?('published_at') && self.published_at.nil?
      self.delete_from_elasticsearch_related_server
    end

    if self.published?
      begin
        h= self.fields_for_search_related
        uri=URI.parse("#{Elasticsearch::Base::RELATED_URI}/#{self.class.to_s.tableize}/#{self.id}")
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          data = h.to_json
          response = http.send_request("PUT", uri.request_uri, data, headers)
          # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
          logger.info "Elasticsearch RELATED Response #{self.class.name} #{self.id}: #{response.code} #{response.message}"
        end
      rescue
        logger.info "Elastic search server is not available. Probably, item #{self.class.name} #{self.id} has not been correctly indexed"
      end
    end
  end

  def delete_from_elasticsearch_related_server
    begin
      uri=(URI.parse("#{Elasticsearch::Base::RELATED_URI}/#{self.class.to_s.tableize}/#{self.id}"))
      Net::HTTP.start(uri.host, uri.port) do |http|
        response = http.send_request("DELETE", uri.request_uri)
        # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
        logger.info "Elasticsearch RELATED Response #{self.class.name} #{self.id}: #{response.code} #{response.message}"
      end
    rescue => e
      logger.info "Elasticsearch server is not available. Probably, item #{self.class.name} #{self.id} has not been correctly indexed. #{e}"
    end
  end

end
