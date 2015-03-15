xml.instruct!
xml.event do
  xml.id @event.id
  xml.titulo @event.title
  xml.fecha_hora @event.pretty_dates
  xml.lugar @event.pretty_place
  xml.direccion @event.location_for_gmaps
  xml.lat @event.lat
  xml.lng @event.lng
  xml.asisten @event.speaker
  xml.organismo do
    xml.title @event.organization.name
    xml.link @event.organization.gc_link
  end
  xml.descripcion @event.microformat_body

  xml.tags do
    for tag in @event.tag_list
      xml.tag tag
    end
  end

  cobertura = event_coverage4xml(@event)
  xml.cobertura do
    xml.estado cobertura[:estado]
    xml.imagen cobertura[:imagen] if cobertura[:imagen]
    xml.iframe_src cobertura[:iframe] if cobertura[:iframe]    
    xml.url cobertura[:url] if cobertura[:url]        
  end

end
