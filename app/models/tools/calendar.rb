module Tools::Calendar
  
  # Calendar specific methods

  module InstanceMethods
    
    # Indica si el evento es de un día o no.
    def one_day?
      self.starts_at.to_date.to_s.eql?(self.ends_at.to_date.to_s)
    end
  
    # Indica si el evento tiene especificada la hora de inicio.
    def has_hour?
      self.starts_at.strftime('%H%M') != "0000"
    end

    # Devuelve el año de la fecha de inicio del evento.
    def year
      @year || self.starts_at.year
    end

    # Devuelve el mes de la fecha de inicio del evento.
    def month
      @month || self.starts_at.month
    end

    # Devuelve el día de la fecha de inicio del evento.
    def day
      @day || self.starts_at.day
    end

    # Valor que se usa para ordenar los eventos dentro de un día.
    # Primero salen los eventos del día, ordendos por hora y
    # al final los eventos que abarcan más de un día.
    def sort_position
      pos = self.one_day? ? 0 : 1000
      pos += self.starts_at.hour
    end    

    # Devuelve del primer día del evento para el mes y el año indicados.
    # Por ejemplo, para un evento que empieza el 30 de enero y acaba el 2 de febrero
    # esta función devolverá 30 cuando <tt>for_moth = 1</tt> y 1 cuando <tt>for_month=2</tt>.
    def first_day(for_month, for_year)
      for_date = Date.parse("#{for_year}-#{for_month}-1").at_beginning_of_month
      if (self.starts_at.to_date > for_date.end_of_month) || (self.ends_at.to_date < for_date)
        the_day = nil
      else
        if self.starts_at.to_date > for_date
          the_day = self.starts_at.day
        else
          the_day = 1
        end
      end
      the_day
    end

    # Devuelve una lista con los día del evento para el mes y el año indicados.
    # Por ejemplo, para un evento que empieza el 30 de enero y acaba el 2 de febrero
    # esta función devolverá [30, 31] cuando <tt>for_moth = 1</tt> y [1,2] cuando <tt>for_month=2</tt>
    #
    def days(for_month=nil, for_year = nil)
      days_list = []
      if self.one_day?
        days_list = [self.day]
      else
        for_month ||= self.starts_at.month
        for_year  ||= self.starts_at.year

        check_date = Date.parse("#{for_year}-#{for_month}-1").at_beginning_of_month

        if (self.starts_at.to_date > check_date.end_of_month) || (self.ends_at.to_date < check_date)
          days_list = []
        else
          # logger.debug "............................. for_month = #{for_month}, for_year = #{for_year}"
          # logger.debug "............................. ends_at = #{self.ends_at}"
          first_day =  (self.starts_at.to_date >= check_date) ? self.starts_at.day : 1
          last_day =  (self.ends_at.to_date <= check_date.at_end_of_month) ?  self.ends_at.day : check_date.end_of_month.day

          # logger.debug "....................... first_day = #{first_day}, last_day = #{last_day}"
          days_list = (first_day..last_day).to_a
        end
      end
      days_list
    end    
  end  
 
  module ClassMethods

    # Devuelve la lista de eventos del mes y año indicados.
    def month_events(month, year)
      start_day = Time.zone.parse("01/#{month}/#{year}")
      end_day = start_day.end_of_month
      # self.where(['starts_at >= ? AND starts_at <= ?', start_day, end_day])
      #                 .order("starts_at")
      self.where(['starts_at <= :end_day AND (ends_at >= :start_day)', {:start_day => start_day, :end_day => end_day}]).order("starts_at")
    end
  
    # Devuelve una lista con los eventos para cada día del mes y año indicados. 
    # Para los eventos que abarcan más de un día hay una entrada para cada día del evento.
    def month_events_by_day(month, year)
      events = self.month_events(month, year)
      events4day = events.group_by  {|e| e.first_day(month, year)}
      events.each do |evt|
        if !evt.one_day?
          evt.days(month, year).each do |day|
            events4day[day] = [] if events4day[day].blank?
            events4day[day].push(evt) unless events4day[day].include?(evt)
          end
        end
      end
      events4day
    end

    # Prepara la lista de eventos del mes y año indicadas para usarla en el calendario del mes.
    def month_events_by_day4cal(month, year)
      events = {}
    
      first_day = Date.civil(year, month, 1)
      last_day = Date.civil(year, month, -1)
    
      self.where([ "(starts_at <= :end_of_day) and (ends_at >= :beginning_of_day)", 
                                       {:beginning_of_day => (first_day-6.days).beginning_of_day,
                                        :end_of_day => (last_day + 6.days).end_of_day}]).order("starts_at").each do |evt|
         if evt.one_day?
           events[evt.month] = {} if events[evt.month].blank?
           events[evt.month][evt.day] = [] if events[evt.month][evt.day].blank?
           events[evt.month][evt.day].push(evt) unless events[evt.month][evt.day].include?(evt)
         else
           # logger.debug ".......................... more than one day event #{evt.pretty_dates}"
         
           if (evt.starts_at.month > evt.ends_at.month)
             if (month >= evt.starts_at.month) 
               prev_year = year 
               next_year= year + 1
             else
               prev_year = year - 1 
               next_year = year
             end
             (evt.starts_at.month .. 12).each do |m|
               events[m] = {} if events[m].blank?
               evt.days(m, prev_year).each do |day|
                 events[m][day] = [] if events[m][day].blank?
                 events[m][day].push(evt) unless events[m][day].include?(evt)
               end
             end
              start_month = 1
           else
             prev_year = year - 1
             next_year= year
             start_month = evt.starts_at.month
           end
         
           (start_month .. evt.ends_at.month).each do |m|
             events[m] = {} if events[m].blank?
             evt.days(m, next_year).each do |day|
               events[m][day] = [] if events[m][day].blank?
               events[m][day].push(evt) unless events[m][day].include?(evt)
             end
           end
         
         end
         # logger.debug ".............. events months: #{events.keys.join(",")}"
         # logger.debug "............. by now for month #{month}"
         # if events[month]
         #   events[month].each do |day, evts|
         #     logger.debug "day: #{day}"
         #     logger.debug "eventos: #{evts.map {|e| e.pretty_dates}.join('\n')}"
         #   end
         # end       
      end
        
      events
    end
    
    def day_events(day, month, year)
      all_events = month_events_by_day(month, year)
      all_events[day].present? ? all_events[day] : []
    end
  end
  
end