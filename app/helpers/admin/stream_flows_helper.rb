# encoding: UTF-8
module Admin::StreamFlowsHelper
  
  # Devuelve las clases que corresponden al DOM con el flujo de _stream_.
  def sf_td_class(sf)
    cnames = []
    if sf
      cnames.push("not_show_in_irekia") unless sf.show_in_irekia?

      cnames.push("not_announced_in_irekia")  unless sf.announced_in_irekia?
      
      cnames.push("in1h") if sf.to_be_shown?(60)

      cnames.push("show_in_irekia") if sf.show_in_irekia?

      cnames.push("announced_in_irekia")  if sf.announced_in_irekia?
            
    end
    cnames.join(" ")
  end

  # Devuelve <tt>true</tt> si hay que mostrar los botones para la web <tt>web</tt>.
  # Por defecto los botones sí se muestran. Si está definido el método <tt>streaming_for_#{web}?</tt> 
  # se usa su valor para decidir si hay que mostrar los botones o no.
  def sf_show_buttons_for(sf, web)
    method = "streaming_for_#{web}?" 
    sf.respond_to?(method) ? sf.send(method) : true
  end

  # Devuelve <tt>true</tt> si hay que mostrar los botones de anunciar/ocultar anuncio de un evento.  
  # Estos botones salen si el stream_flow tiene asignado evento o si está anunciado en Irekia 
  def sf_show_annoucement_links?(sf)
    !sf.event_id.nil? || sf.announced_in_irekia?
  end
  
  # Botón "anunciar en ..."
  def sf_announce_link(sf)
    submit_tag(t("admin.stream_flows.anunciar_streaming"), {:class => "announce_live_irekia", :id => "announce_in_irekia_#{sf.id}", :name => "announce_irekia_on", :onclick => "$('submitted_opt_#{sf.id}').value='announce_irekia_on'"}).html_safe
  end
  
  # Botón "ocultar anuncio en ..."
  def sf_stop_announcing(sf)
    submit_tag(t("admin.stream_flows.ocultar_anuncio_streaming"), {:class => "off_announce_irekia", :id => "hide_announcement_in_irekia_#{sf.id}", :name => "announce_irekia_off", :onclick => "$('submitted_opt_#{sf.id}').value='announce_irekia_off'"}).html_safe
  end
  
  # Botón "empezar a emitir"
  def sf_show_live_button(sf)
    submit_tag(t("admin.stream_flows.empezar_emitir_ahora"), {:class => "start_live_irekia", :id => "show_in_irekia_#{sf.id}", :name => "show_irekia_on", :onclick => "$('submitted_opt_#{sf.id}').value='show_irekia_on'"})
  end
  
  # Botón "dejar de emitir"
  def sf_stop_live_button(sf)
    submit_tag(t("admin.stream_flows.dejar_emitir"), {:class => "off_live_irekia", :id => "hide_in_irekia_#{sf.id}", :name => "show_irekia_off", :onclick => "$('submitted_opt_#{sf.id}').value='show_irekia_off'"})
  end

  # Info sobre el número de personas que ve un streaming
  def admin_show_streaming_watchers(stream_flow)
    streaming_watchers = nil
    Stats::CouchDB.streaming_watchers.each do |title, watchers| 
      if sf = StreamFlow.find_by_title_es(title)
        streaming_watchers = watchers if sf.code.eql?(stream_flow.code) 
      end
    end
    
    content_tag(:p, content_tag(:b, "En este momento (#{I18n.l(Time.zone.now, :format => :short)} ) hay  #{pluralize(streaming_watchers, 'persona')} viendo la emisión.")).html_safe
  end
  
end
