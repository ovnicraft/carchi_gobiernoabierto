module Sadmin::EventsHelper

  # Devuelve el número máximo de eventos que se muestran en una celda del calendario.
  def num_events_in_cell
    @show_in_cell || 3
  end

  #  Asigna valor al número máximo de eventos que se muestran en una celda del calendario.
  def num_events_in_cell=(num)
    @show_in_cell = num.to_i
  end

  # Texto para el enlace a la página del evento.
  def event_link_text(evt, d)
    txt = ""
    if d.to_date.eql?(evt.starts_at.to_date)
      txt += content_tag(:span, I18n.localize(evt.starts_at, :format => :hour), :class => "event_hour") unless evt.starts_at.hour.eql?(0)
    end

    txt += content_tag(:span, h(evt.title[0,10])+(evt.title.size > 10 ? "..." : ""), :class => "event_title irekia_coverage_#{evt.irekia_coverage?}")
    txt.html_safe
  end

  # DOM clases para el _div_ con los datos del evento.
  def event_div_class_name(evt)
    cn = []
    cn.push("irekia_event") if evt.is_public?
    cn.push("private_event") if evt.is_private?
    cn.push("deleted") if evt.deleted?

    cn.join(' ')
  end

  # La URL del evento.
  def event_link_url(evt, opts={})
    sadmin_event_path({:id => evt.id}.merge(opts))
  end

  # Devuelve los datos del evento que salen en una celda del calendario.
  def event_data4table_cell(evt, d, pos)
    content_tag(:div, content_tag(:span,
                                  link_to(event_link_text(evt, d), event_link_url(evt),
                                          :day => d.mday , :month => d.month, :pos => pos, :class => "event_title" )),
                                  :class => "one_event_link #{event_div_class_name(evt)}" ).html_safe
  end

  # Muestra una celda del calendario.
  def render_calendar_cell(d, events, today)
    cell_class = ""
    day_number = ""

    if d.mday == d.beginning_of_week.mday
      day_number = link_to("Semana", week_sadmin_events_path(:day => d.mday, :month => d.month, :year => d.year), :class => "week_link")
    end

    day_number << link_to(d.mday, list_sadmin_events_path(:day => d.mday, :month => d.month, :year => d.year), :class => "day_number")

    txt = content_tag(:div, day_number.html_safe, :class => "day_number")

    if events.blank?
      if (d >= today) && !([0, 6].include?(d.wday))
        cell_class = "normalDay"
      end
    else
      show_in_cell = num_events_in_cell
      events[0,show_in_cell].each_with_index do |evt, i|
        txt << event_data4table_cell(evt, d, i)
      end

      case
        when (events.size == (show_in_cell+1))
          txt << event_data4table_cell(events[show_in_cell], d, show_in_cell)
        when (events.size > (show_in_cell+1))
          txt << content_tag(:div, content_tag(:span,
                                   link_to("+ #{events.size - show_in_cell} #{t('mas')}",
                                           list_sadmin_events_path(:day => d.mday, :month => d.month, :year => d.year))),
                             :class => "more_events_link")
      end

      # link_to(d.mday, "#", :onclick => "showDayInfo(#{d.mday}, this);return false;")
      cell_class="busyDay"
    end

    [txt.html_safe, {:class => "#{cell_class} day#{d.wday}", :id => "d#{d.mday}_#{d.month}"}]
  end

  # Devuelve la información sobre dónde está publicado el evento.
  def event_published_info(evt, only_published = true)
    places = []
    places.push Settings.site_name if evt.is_public?

    return "#{t('en')} #{places.join(' ' + t('y') + ' ')}"
  end

  # Devuelve un texto que indica el estado del evento.
  def event_state_info(evt)
    txt = []

    if evt.published?
      txt << content_tag(:span, t('sadmin.events.evento_publicado_en', :en => event_published_info(evt)), :class => "published_notice")
    elsif evt.published_at.nil?
      txt << content_tag(:span, "Este evento es privado", :class => "unpublished_notice")
    else
      txt << content_tag(:span, t('sadmin.events.publicara_en', :en =>I18n.localize(evt.published_at, :format => :short)), :class => "unpublished_notice")
    end

    if evt.deleted?
      txt = ["<span class='deleted'>#{t('sadmin.events.marcado_eliminado')}</span>"]
    end

    txt.join("<br />").html_safe
  end

  # Devuelve un texto que indica si el evento está confirmado o no.
  def event_confirmed_short_info(evt)
    txt = []

    if !evt.confirmed?
      txt << content_tag(:span, t('sadmin.events.pendiente_confirmar'), :class => "unpublished_notice")
    else
      txt << content_tag(:span, t('sadmin.events.si_confirmado'), :class => "published_notice")
    end

    txt
  end

  # Devuelve un texto con información sobre dónde es visible el evento.
  def event_publication_state_info(evt)
    txt = if evt.is_private?
        "<span class='private_event'>#{t('sadmin.events.uso_interno')}</span>"
    else
      "<span class='public_event #{event_div_class_name(evt)}'>#{t('sadmin.events.visible_en', :en => event_published_info(evt, false))}</span>"
    end

    txt.html_safe
  end

  # Devuelve el enlace a la lista de eventos de un día.
  def one_datetime_with_link(datetime)
    date = datetime.to_date

    txt = link_to(I18n.localize(date, :format => :long), list_sadmin_events_path(:day => date.day, :month => date.month, :year => date.year))
    if datetime.strftime('%H%M') != "0000"
      txt << ", #{I18n.localize(datetime, :format => :hour)}"
    end

    txt
  end

  # Devuelve las fechas del evento como enlaces a la lista de eventos del día.
  def event_dates_with_links(evt)
    start_date = evt.starts_at.to_date
    end_date = evt.ends_at.to_date

    txt = one_datetime_with_link(evt.starts_at)

    if evt.starts_at.to_date.eql?(evt.ends_at.to_date)
      # Same day, different hours
      txt = txt + " - #{evt.ends_at.strftime('%H:%M')}" if evt.ends_at.strftime('%H%M') != "0000"
    else
      # Different dates
      txt = txt + " -- " +one_datetime_with_link(evt.ends_at)
    end

    txt
  end

  # Devuelve la información sobre si Irekia cubre el evento y qué tipo de cobertura se dará.
  def event_coverage_info(evt)
    cov = []
    cov.push(t('photos.title')) if evt. irekia_coverage_photo?
    cov.push(t('videos.title')) if evt. irekia_coverage_video?
    cov.push(t('audios.title')) if evt. irekia_coverage_audio?
    cov.join(", ")
  end

  def event_agenda_check_form_url
    url_params = if params[:action].eql?('index')
      {:action => 'calendar'}
    else
      {:action => params[:action]}
    end
    url_params[:day] = params[:day]
    url_params.merge(:year => @year || Time.zone.now.year, :month => @month || Time.zone.now.month)
  end

  # Indica si el usuairo puede crear sólo un tipo de eventos.
  def can_create_only_one_type_of_event?
    current_user.all_permission_by_module["events"].length == 1
  end

  # Prepara un json string por cada evento
  def event_json_for_sf(evt)
    title = "#{evt.title.gsub(/'/,"\"")}, #{evt.pretty_hours}"
    "'title':'#{title}', 'stream_flow_id':'#{evt.stream_flow_id}', 'streaming_for':'#{evt.streaming_for}'"
  end

  # Muestra las webs donde el evento se va a emitir en directo con el aviso
  # correspondiente si hay otro evento al mismo tiempo en la misma web.
  def show_web_streaming_info_for_admin(event)
    txt = event.streaming_for_pretty
    overlapped = event.overlapped_streaming

    unless overlapped.empty?
      info = {}
      event.streaming_places.each do |place|
        info[place] ||= []
        overlapped.each do |oevt|
          if oevt.streaming_for?(place)
            info[place].push  link_to("#{oevt.title.gsub(/'/,"\"")}, #{oevt.pretty_hours}", admin_document_path(oevt))
          end
        end
      end
      unless info.values.flatten.empty?
        txt = [""]
        info.each do |place, oevts|
          txt.push content_tag(:span, "#{t("events.#{place.strip}")} #{content_tag(:span, "AVISO: Coincide con #{oevts.to_sentence}", :class => 'overlap_info') unless oevts.empty?}", :class => 'streaming_place_info')
        end
        txt = txt.join("<br />")
      end
    end

    txt
  end

end
