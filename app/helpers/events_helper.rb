module EventsHelper  
  
  def location_pretty(item, join_with="<br />")
    [h(item.pretty_place), h(item.location_for_gmaps)].compact.join(join_with).html_safe    
  end
    
  def event_location_pretty(event)
    content_tag(:span, location_pretty(event), :class => "location")
  end
  
  def event_date_pretty(event, delimiter = " - ")
    [event.starts_at.to_date, event.ends_at.to_date].uniq.map {|date| l(date, :format => :long)}.join(delimiter)
  end
  
  def event_link(event_or_stream_flow)
    link = event_or_stream_flow.title
    if event_or_stream_flow.is_a?(StreamFlow) 
      sf = event_or_stream_flow
      link = link_to(sf.title, streaming_path(sf))
    else
      event = event_or_stream_flow
        if event.is_public?
          link = link_to(event.title, event_path(event))
        else
          link = link_to(event.title, streaming_path(event.stream_flow))
        end
    end
    link
  end
  
  def streaming_url(event_or_stream_flow)
    link = ""
    if event_or_stream_flow.is_a?(StreamFlow) 
      link = streaming_path(event_or_stream_flow)
    else
      event = event_or_stream_flow
      if event.is_public?
        link = event_path(event)
      else
        link = streaming_path(event.stream_flow)
      end
    end
    link
  end
  
  # Estado para el formato XML
  def event_coverage4xml(event)
    cov4xml = {:estado => 'no', :imagen => nil, :iframe_src => nil, :url => nil}
    if event.stream_flow
      cov4xml[:estado] = 'previsto'
      if event.on_air?
        cov4xml[:estado] = 'emitiendo'
        cov4xml[:iframe] = "http://#{request.host_with_port}/iframe/streaming/#{@event.stream_flow.id}"
      else
        if event.announced?
          cov4xml[:estado] = 'anunciado'
          cov4xml[:imagen] = "http://#{request.host_with_port}#{@event.stream_flow.photo_path}"
        else
          if event.passed?
            if related_news = event.related_news_published
              cov4xml[:estado] = 'noticia'
              cov4xml[:url] = "http://#{request.host_with_port}#{news_path(related_news)}"
            end
          end
        end
      end
    else
      if related_news = event.related_news_published
        cov4xml[:estado] = 'noticia'
        cov4xml[:url] = "http://#{request.host_with_port}#{news_path(related_news)}"
      else
        cov4xml[:estado] = 'sin cobertura'
      end
    end
    cov4xml
  end
  
  def event_or_streaming_current_status(event, streaming=nil)
    sstatus = ''
    if event.present?
      sstatus = event.stream_flow.present? ? event.streaming_status : event.current_status
    else
      if streaming.present?
        if streaming.on_air?
          sstatus = 'live'
        else
          if streaming.announced?
            sstatus = 'announced'
          else
            sstatus = 'unknown'
          end      
        end
      end
    end
    sstatus
  end
  
  # Mostrar información sobre el estado del streaming si el estado es 'anunciado', 'emitiendo' o 'programado'
  def show_streaming_status?(current_status)
    ['announced', 'live', 'programmed'].include?(current_status)
  end
  
  def render_public_calendar_cell(d, events, today)
    cell_class = []
    if @context
      day_number = link_to(d.mday, send("#{@context.class.to_s.downcase}_events_path", :day => d.mday, :month => d.month, :year => d.year, "#{@context.class.to_s.downcase}_id".to_sym => @context.id, :anchor => 'middle'), :class => "day_number")
    else
      day_number = link_to(d.mday, events_path(:day => d.mday, :month => d.month, :year => d.year), :class => "day_number")
    end
    
    txt = content_tag(:div, day_number, :class => "day_number")
    if (d >= today) && !([0, 6].include?(d.wday))
      cell_class << "normalDay"
    end
    cell_class << if events.blank?
      'empty'
    elsif events.length.between?(1, 3)  
      'f1to3events'
    elsif events.length.between?(3, 5)  
      'f3to5events'  
    elsif events.length.between?(5, 7)    
      'f5to7events'  
    elsif events.length > 7
      'mt7events'
    end  
    lparams = {:day => d.mday, :month => d.month, :year => d.year}
    if @context.present? && @context.is_a?(Area)
      lparams.merge!(:area_id => @context.id)
    elsif @context.present? && @context.is_a?(Politician)
      lparams.merge!(:politician_id => @context.id)
    end  
      
    txt << content_tag(:div, link_to(t('events.count', :count => events.length), events_path(lparams)), :class => 'events') if events.present?
    
    [txt, {:class => "#{cell_class.join(' ')} day#{d.wday}", :id => "d#{d.mday}_#{d.month}"}]
  end
  
  # Muestra la información sobre la cobertura que de Irekia al evento.
  # Devuelve un html con la información disponible:
  # span.marked
  # span.go2streaming
  # span.coverage_footnote_mark
  # Se usa tanto en la lista de eventos como en la página de un evento.
  def coverage_and_streaming_for(event, where="", opts={})
    txt = ""
    cov_types = []

    items = ["irekia_coverage_audio", "irekia_coverage_video", "irekia_coverage_photo"]
    if event.irekia_coverage? || event.streaming_live?
      items.each do |cov_type|
        cov_types << t("events.#{cov_type}") if event.send("#{cov_type}?")
      end
      if where.eql?('all')
        ss = event.streaming_for_pretty(@locale)
        cov_types << t("events.streaming_for_subsites", :subsites => ss) if ss.present?
      else
        cov_type = "streaming_for_irekia"
        cov_types << t("events.#{cov_type}") if event.send("#{cov_type}?")
      end
    end
    
    if where.eql?('all')
      cov_type = 'irekia_coverage_article'
      # mostrar el info sobre la crónica también
      cov_types << t("events.#{cov_type}") if event.send("#{cov_type}?")
    end

    unless cov_types.empty?
      if event.on_air?
        info = t("events.streaming_status.live")
      else
        cov_types_str = cov_types.to_sentence
        info = t("events.irekia_#{event.passed? ? 'covered' : 'coverage'}", :cov_types => cov_types_str, :site_name => Settings.site_name)
      end  
      go2news = ""
      if opts[:show_related_news] && event.passed? && related_news = event.related_news_published
        go2news = link_to(t('events.ver_video').capitalize, related_news_url(related_news), :class => "go2news")+"." if related_news.has_video?
      end
      info_txt = content_tag(:span, "#{info.mb_chars.upcase.to_s}. #{go2news}", :class => "marked #{'with_link' if go2news.present?}")
       
      go2streaming = ""
      if event.on_air?
        go2streaming = content_tag(:span, link_to(t('events.ver_streaming'), event_path(event)), :class => 'go2streaming')
      end
            
      txt = content_tag :div, :class => "coverage c4#{where}" do
        content_tag(:div, info_txt + go2streaming, :class => 'info_and_link')
      end
    end
    
    txt.html_safe
  end
  
  def event_day_for_icon(evt)
    date = evt.starts_at.to_date
    
    if !evt.one_day? 
      # Evento de más de un día. Si ya ha empezado se pone fecha de hoy. 
      # Si no ha empezado o ya ha acabado se pone la fecha de inicio.
      if (evt.starts_at.to_date > Time.zone.now.to_date) || evt.passed?
        date = evt.starts_at.to_date
      else
        date = Time.zone.now.to_date
      end
    end
    
    date
  end
  
  def icon_for_day(evt)
    date = event_day_for_icon(evt)
    link_to(content_tag(:span, I18n.localize(date, :format => :abbr_month), :class => "month")+content_tag(:span, date.day.to_s, :class => "day"), event_url(evt), :class=>"date_icon")
  end

  def show_irekia_coverage_footnote(events, always=false)
    if always || events.detect {|item| item.is_a?(Event) && item.irekia_coverage? && !item.current_status.eql?('passed')}
      content_tag(:div, "(*) #{t('events.irekia_coverage_footnote', :publisher_name => Settings.publisher[:name], :publisher_address => Settings.publisher[:address])}", :class => "coverage_footnote")
    end
  end
    
end
