module Elasticsearch::Search
  module ClassMethods
    def full_query(q, filters, from=0, sort=nil, only_title=false, locale=I18n.locale, size = Elasticsearch::Base::ITEMS_PER_PAGE)
      # , 'indices_boost' => {'irekia4' => 2.5, 'bopv' => 1}
      fq = { 'explain' => true, 'size' => size,
             'from' => "#{from.to_i}", 'query' => query(q, filters, only_title, locale), 'facets' => facets }
      fq.merge!(sort_string(sort))
      fq
    end

    def query(q, filters, only_title, locale)
      if filters.present?
        { 'filtered' => { 'query' => query_string(q, only_title, locale) }.merge(filters(filters)) }
      else
        # query_string(q.gsub(' AND ', ' ').gsub(/\s+/, ' AND '))
        query_string(q.gsub(/\s+/, ' '), only_title, locale)
      end
    end

    def query_string(q, only_title, locale)
      if only_title
        fields = ['title_es^7', 'title_eu^7', 'title_en^7']
      else
        fields = ['title_es^7', 'title_eu^7', 'title_en^7', 'body_es', 'body_eu', 'body_en', 'tags^6', 'year', 'month',
          'organization^5', 'areas^5', 'politicianst^5', 'speaker^4', 'public_name^7', 'role^7', 'subtitles_es', 'subtitles_eu', 'subtitles_en']
        fields_bopv = ['materias', 'seccion', 'rango', 'organo', 'no_bol', 'no_disp', 'no_orden']
        fields = fields + fields_bopv
      end
      { 'query_string' => { 'fields' => fields, 'query' => "#{q}", 'default_operator' => 'AND', 'analyzer' => analyzer(locale)} }
    end

    def filters(filters)
      f=[]
      filters.each do |term|
        case term[0]
        when 'date'
          f << {'range' => {'published_at' => Elasticsearch::Base::DATE_RANGES[term[1]]}}
        else
          f << {'term' => {term[0] => term[1] } }
        end
      end
      {'filter' => { 'and' => f }}
    end

    def analyzer(locale)
      case locale.to_s
      when 'eu'
        'basque'
      when 'en'
        'english'
      else
        'default'
      end
    end

    def facets
      fh = Hash.new
      Elasticsearch::Base::FACETS.each_pair do |facet, att|
        value = {'field' => att[:field], 'size' => att[:size]}
        value.merge!(att[:other]) if att[:other].present?
        fh[facet] = { att[:type] => value }
      end
      fh
    end

    def sort_string(sort)
      if sort.present? && sort.eql?('date')
        {'sort' => {'published_at' => {'order' => 'desc'} }}
      else
        {'sort' => ['_score', {'published_at' => {'order' => 'desc'} }]}
      end
    end

    def connect_to_elasticsearch(data, options={})
      es_uri = Elasticsearch::Base::URI.dup
      if Elasticsearch::Base::BOPV_URI && !Rails.env.eql?('test')
        es_uri << ",#{Elasticsearch::Base::BOPV_URI.split('/').last}"
      end
      options.merge!(:pretty => true)
      # Elasticsearch::Base::log "QUERY STRING: #{data.inspect}"
      begin
        uri=(URI.parse("#{es_uri}/_search?#{options.to_query}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          response = http.send_request("GET", uri.request_uri, data, headers)
          # Elasticsearch::Base::log "ElasticSearch#search response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "ElasticSearch#search response: #{response.code} #{response.message}"
          @code=response.code
          @body=response.body
        end
      rescue => e
        Elasticsearch::Base::log "ElasticSearch#search ERROR #{e}"
        return []
      end
      return @code, @body
    end

    def build_query(criterio)
      q=[]
      filters=[]
      criterio.title.split(' AND ').each do |member|
        if member[/keyword: /]
          if criterio.only_title
            q.push(member.gsub('keyword: ', '').to_s.tildes)
          else
            q.push(member.gsub('keyword: ', '').to_s.escape_for_elasticsearch2.tildes)
          end
        elsif member[/tags: |organization: |areas: |politicianst: |seccion: |rango: |organo: |materias: /]
          key=member[/tags: |organization: |areas: |politicianst: |seccion: |rango: |organo: |materias: /]
          filters.push(["#{key.split(':').first}.analyzed", member.split(key).last])
        elsif member[/type: /]
          filters.push(['_type', member.split('type: ').last])
        elsif member[/date: |year: |month: |term: /]
          key=member[/date: |year: |month: |term: /]
          filters.push([key.split(':').first, member.split(key).last])
        else
          q.push(member)
        end
      end
      q=q.join(' ')
      q = '*' if q.empty?
      return q, filters
    end

    def do_elasticsearch_with_facets(criterio, from, sort=nil, only_title=false, locale=I18n.locale, size = Elasticsearch::Base::ITEMS_PER_PAGE)
      q, filters = build_query(criterio)
      qs=full_query(q, filters, from, sort, only_title, locale, size)
      @code, @body = connect_to_elasticsearch(qs.to_json)

      if @code.eql?('200')
        results=Hash.new
        results['hits']=[]

        results['total_hits'] = JSON.parse(@body)['hits']['total']

        if results['total_hits'] == 0
          # no results found. Use suggestions
          term = criterio.last_part.gsub('keyword: ', '').to_s.escape_for_elasticsearch2.gsub(/([\"])/, '').tildes
          raw_suggest_query = "{\"suggest\":{\"irekia4-suggestion\":{\"text\": \"#{term}\", \"term\": {\"field\": \"4suggestions\"}}}}"

          @code, @body = connect_to_elasticsearch(raw_suggest_query)

          if @code.eql?('200')
            body = JSON.parse(@body)
            suggestions = body['suggest']['irekia4-suggestion']
            if suggestions.present? && suggestions.size > 0
              results['suggestion'] = suggestions.map{|a| a['options'].present? ? a['options'].first['text'] : a['text']}.join(' ')
              q = q.gsub(term, results['suggestion'])
              # repeat query with suggestion
              qs=full_query(q, filters, from, sort, only_title, locale)
              @code, @body = connect_to_elasticsearch(qs.to_json)
            end
          end
        end

        body = JSON.parse(@body)

        unless body['error'].present?
          results['total_hits'] = body["hits"]['total']
          if body["hits"].present?
            body["hits"]["hits"].each do |result|
              # Elasticsearch::Base::log "### #{result['_type']}, #{result['_id']}, score #{result['_score']}"
              item=result['_type'].classify.constantize.find_by_id(result["_id"])
              if item.present?
                item.score = result['_score']
                item.explanation = result['_explanation']
                results['hits'].push(item)
              end
            end
          end

          results['facets']=Hash.new
          facets_body=JSON.parse(@body)['facets']

          # Facets
          if facets_body.present?
            Elasticsearch::Base::FACETS.keys.each do |att|
              if att.eql?('date')
                terms='ranges'
              else
                terms='terms'
              end
              results['facets'][att]=[]
              facets_body[att][terms].each do |facet|
                unless facet['count'].zero?
                  case att
                  when 'date'
                    value=Elasticsearch::Base::DATE_IN_HOURS[((facet['from'] - facet['to']).to_i.abs/3600000)]
                  else
                    value=facet['term']
                  end
                  results['facets'][att].push([value, facet['count']])
                end
              end
            end
          end
        else
          return []
        end
      else
        return []
      end
      results
    end

    def do_elasticsearch_for_ios(criterio, type, from, locale=I18n.locale)
      # qs=full_query(q, nil, from, nil, 15)
      q, filters = build_query(criterio)
      qs=full_query(q, filters, from, nil, false, locale)

      Elasticsearch::Base::log "QUERY STRING: #{qs.inspect}"
      begin
        uri=(URI.parse("#{Elasticsearch::Base::URI}/#{type}/_search?pretty=true"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          data = qs.to_json
          response = http.send_request("GET", uri.request_uri, data, headers)
          # Elasticsearch::Base::log "ElasticSearch#search response: #{response.code} #{response.message} #{response.body}"
          # Elasticsearch::Base::log "ElasticSearch#search response: #{response.code} #{response.message}"
          @code=response.code
          @body=response.body
        end
      rescue => e
        Elasticsearch::Base::log "ElasticSearch#search ERROR #{e}"
        return []
      end

      if @code.eql?('200')
        results=Hash.new
        results['hits']=[]

        results['total_hits'] = JSON.parse(@body)['hits']['total']
        JSON.parse(@body)["hits"]["hits"].each do |result|
          # Elasticsearch::Base::log "### #{result['_type']}, #{result['_id']}, score #{result['_score']} "
          item=result['_type'].classify.constantize.find_by_id(result["_id"])
          results['hits'].push(item) if item.present?
        end
      else
        return []
      end
      results
    end
  end

  module ViewHelpers
    ActionView::Base.send :include, ViewHelpers

    def will_paginate_search(collection, total)
      output=[]
      current=@page.to_i
      per_page=Elasticsearch::Base::ITEMS_PER_PAGE
      last_page=lastpage(total, per_page)
      min=minmaxpage(current, last_page, 'min')
      max=minmaxpage(current, last_page, 'max')

      # Previous page
      aux = []
      if min < current
        aux << link_to_page(t('search.anterior'), current-1)
      else
        aux << content_tag(:span, t('search.anterior'))
      end
      output << content_tag(:li, aux.join.html_safe, :class => 'prev_page')

      # Page numbers
      aux=[]
      if min > 1
        aux << link_to_page(1, 1)
        aux << content_tag(:span, " ... ", :class => 'gap')
      end
      x=min
      while x <= max
        if x.to_i == current.to_i
          aux << content_tag(:span, x, :class => 'current')
        else
          aux << link_to_page(x.to_s, x)
        end
        x=x+1
      end
      x=x-1

      if x == 1 || total <= Elasticsearch::Base::ITEMS_PER_PAGE
        ""
      else
        if max < last_page
          aux << content_tag(:span, " ... ", :class => 'gap')
          aux << link_to_page(last_page.to_s, last_page)
        end
        output << content_tag(:li, aux.join('   ').html_safe, :class => 'page_numbers')

        # Next page
        aux=[]
        if max > current
          aux << link_to_page(t('search.siguiente'), current + 1)
        else
          aux << content_tag(:span, t('search.siguiente'))
        end
        output << content_tag(:li, aux.join.html_safe, :class => 'next_page')
        content_tag(:div, content_tag(:ul, output.join.html_safe), :class => 'pagination')
      end
    end

    def link_to_page(text, page)
      link_params={:page => page}
      if @criterio.present? && !@criterio.new_record?
        link_params.merge!(:id => @criterio.id)
        link_uri='search_path'
      else
        link_uri = 'new_search_path'
      end
      link_params.merge!(:sort => @sort) if @sort.present?
      link_to(text, send(link_uri, link_params))
    end

    def lastpage(total, per_page)
      last_page = total/per_page + 1
      if total%per_page == 0
        last_page = last_page - 1
      end
      return last_page
    end

    def minmaxpage(current, total_pages, option)
      min = current - 2
      if min < 1
        min = 1
        max = 1 + 4
        if max > total_pages then max = total_pages end
      end
      max = min + 4
      if max > total_pages
        max = total_pages
        min = max - 4
        while min < 1
          min = min + 1
        end
      end
      if option.eql?('min') then return min else return max end
    end
  end
end
