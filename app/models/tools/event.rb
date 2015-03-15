module Tools::Event
  include Geokit::Geocoders

  # Indica si el evento ya ha pasado
  def passed?
    (self.ends_at < Time.zone.now) && !((self.ends_at.to_date.eql?(Time.zone.now.to_date)) && self.ends_at.strftime('%H%M').eql?("0000"))
  end
  
  # Indica si el evento empieza o acaba entre <tt>first_day</tt> y <tt>last_day</tt>.
  def between?(first_day, last_day)
    ((self.ends_at.to_date >= first_day) && (self.ends_at.to_date <= last_day)) || ((self.starts_at.to_date >= first_day) && (self.starts_at.to_date <= last_day))
  end
  
  # Fomatea la descripción del evento.
  def pretty_body
     body ? body.sub(/<p.*>###<.*\/p>/, '') : ""
  end
  
  # Muestra las fechas del evento en el idioma correspondinte con el formato para este idioma.
  # Si está indicada la hora, ésta también se muestra.
  def pretty_dates(locale=I18n.locale)
    if starts_at.eql?(ends_at)
      if starts_at.strftime('%H%M') == "0000"
        # Remove hour if it is scheduled for midnight
        I18n.localize(starts_at.to_date, :format => :long, :locale => locale)
      else
        I18n.localize(starts_at, :format => :long, :locale => locale)
      end
    elsif starts_at.to_date.eql?(ends_at.to_date)
      # Same day, different hours
      "#{I18n.localize(starts_at.to_date, :format => :long, :locale => locale)}, #{starts_at.strftime('%H:%M')} - #{ends_at.strftime('%H:%M')}" 
    else
      # Different dates
      start_date = starts_at.strftime('%H%M') == "0000" ? I18n.localize(starts_at.to_date, :format => :long, :locale => locale) : I18n.localize(starts_at, :format => :long, :locale => locale)
      end_date = ends_at.strftime('%H%M') == "0000" ? I18n.localize(ends_at.to_date, :format => :long, :locale => locale) : I18n.localize(ends_at, :format => :long, :locale => locale)
      "#{start_date} - #{end_date}"
    end
  end
  
  # Muestra las horas de inicio y final del evento.
  def pretty_hours(locale=I18n.locale)
    if starts_at.to_date.eql?(ends_at.to_date)
      # Same day, different hours
      "#{starts_at.strftime('%H:%M')} - #{ends_at.strftime('%H:%M')}" 
    else
      # Different dates
      start_date = starts_at.strftime('%H%M') == "0000" ? I18n.localize(starts_at.to_date, :format => :long, :locale => locale) : I18n.localize(starts_at, :format => :long, :locale => locale)
      end_date = ends_at.strftime('%H%M') == "0000" ? I18n.localize(ends_at.to_date, :format => :long, :locale => locale) : I18n.localize(ends_at, :format => :long, :locale => locale)
      "#{start_date} - #{end_date}"
    end    
  end
  
  # Muestra la información sobre el lugar del evento.
  def pretty_place
    full_info = [self.place, self.city].map {|e| e.blank? ? nil : e }.compact
    full_info.empty? ? "" : full_info.join(", ")
  end
  
  # Muestra la descripción del evento en formato apropiado para usarlo como _microformat_
  def microformat_body
    m = body.to_s.match(/(.+)<p.*>###<\/p>(.+)/m)
    # m = body.match(/((.+?)<\/p>)/m)
    if m 
      b = "<div class='description'>#{m[1]}</div>
        #{m[2]}"
    else
      b = body
    end
    return b
  end
  
  # # Muestra una descripción corta del evento. 
  # # Se usa en el meta og:description
  # def short_description
  #   m = body.to_s.match(/(.+)<p.*>###<\/p>(.+)/m)
  #   txt = m.present? ? m[1] : self.body
  #   txt.strip_html
  # end
  
  # Añade a la lista de errors una entrada si la fecha de inicio es posterior a la de fin del evento.
  #
  # Método que se usa en <tt>after_save</tt>.
  def ends_later_than_it_starts
    errors.add(:base, "La fecha de fin debe ser posterior a la de inicio") if self.ends_at < self.starts_at
  end
  
  # Rellena los datos de longitud y latitud.
  #
  # Método que se usa en <tt>after_save</tt>.
  def fill_lat_lng_data
    if location_for_gmaps_changed? || place_changed?
      # Primero miramos en la lista de lugares comunes
      if eloc = EventLocation.find_by_place_and_city_and_address(self.place, self.city, self.location_for_gmaps)
        self.lat, self.lng = eloc.lat, eloc.lng
      else      
        if "#{location_for_gmaps} #{city}".blank?
          self.lat = self.lng = nil
        else
          # Preguntar a Google
          full_location = "#{location_for_gmaps}, #{city}, Spain"
          loc = GoogleV3Geocoder.geocode("#{full_location}")
          unless loc.success
            loc = GoogleV3Geocoder.geocode(location_for_gmaps)
          end

          if loc.success
            self.lat, self.lng = loc.lat, loc.lng
          end
        end
      end
    end
  end

  # Indica si el evento <tt>self</tt> y el <tt>evt2</tt> son del mismo día.
  def same_day?(evt)
    self.starts_at.to_date.eql?(evt.starts_at.to_date)
  end
  
end
