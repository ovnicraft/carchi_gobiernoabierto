# Clase para los eventos. Es subclase de Document, por lo que su tabla es <tt>documents</tt>
class Event < Document
  include Floki

  include Tools::Event

  include Tools::Calendar::InstanceMethods
  extend Tools::Calendar::ClassMethods
  include Floki

  include ActsAsCommentable
  include Tools::Clickthroughable

  has_many :alerts, :class_name => "EventAlert", :foreign_key => "event_id", :dependent => :destroy
  # HT
  has_many :tweets, :class_name => "DocumentTweet", :foreign_key => "document_id", :dependent => :destroy
  # has_many :sent_tweets, -> { where("tweeted_at IS NOT NULL")}, :class_name => "DocumentTweet", :foreign_key => "document_id"

  # Noticia o video relacionado. Por ahora se usa sólo para asignar una noticia a un evento.
  has_many :related_items, :class_name => "RelatedEvent", :dependent => :destroy
  attr :related_news_title

  # Es un atributo que sólo se usa en el formulario de contenido adicional para un evento.
  attr_accessor :draft_news

  # Información sobre qué periodistas pueden ir al evento
  attr_accessor :only_photographers
  attr_accessor :all_journalists
  attr_accessor :alert_this_change

  def alert_this_change
    value = (@alert_this_change ? (@alert_this_change != 0) : self.alertable)
    return value
  end

  def alert_this_change=(val)
    @alert_this_change = val.to_i
    return @alert_this_change
  end

  belongs_to :organization

  belongs_to :stream_flow
  STREAMING4 = [:irekia, :en_diferido]

  STREAMING4.each do |place|
    define_method "streaming_for_#{place}" do
      current_val = self.instance_variable_get("@streaming_for_#{place}")
      db_val = (self.instance_variable_get("@streaming_for") || self.streaming_for).to_s.split(",").map {|e| e.strip}.include?(place.to_s) ? 1 : 0
      self.instance_variable_set("@streaming_for_#{place}", current_val.nil? ? db_val : current_val.to_i )
    end

    define_method "streaming_for_#{place}?" do
      self.send("streaming_for_#{place}").eql?(1)
    end

    define_method "streaming_for_#{place}=" do |val|
      self.instance_variable_set("@streaming_for_#{place}", val.to_i)
    end

  end
  before_save :set_streaming_for


  attr_accessor :is_private

  # Días de antelación para las alertas de eventos de la AM
  ALERTS_BEFOREHAND = 3.days

  # Eventos en curso: los que empiezan hoy, o han empezado antes y acaban hoy o mañana
  scope :current, ->(*args) { where([ "(starts_at <= :end_of_day) and (ends_at >= :beginning_of_day)", 
    { :beginning_of_day => (args.first || Time.zone.now).beginning_of_day, :end_of_day => (args.first || Time.zone.now).end_of_day}]).order("starts_at DESC") }

  # Eventos futuros: los que acaban a partir de mañana.
  scope :future, ->(*args) { where([ "(ends_at > :end_of_day)", {:end_of_day => (args.first || Time.zone.now).end_of_day}]).order("starts_at DESC")}

  # Eventos pasados: los que acaban a antes de hoy.
  scope :passed, ->(*args) { where([ "(ends_at < :beginning_of_day)", {:beginning_of_day => (args.first || Time.zone.now).beginning_of_day}]).order("starts_at DESC") }

  # Redefine the document named scopes here
  scope :published, ->(*args) { where(["published_at IS NOT NULL AND published_at <= ?", (args.first || Time.zone.now)]).order("starts_at ASC")}

  scope :translated, -> { where("coalesce(title_#{I18n.locale.to_s}, '') <> ''")}

  scope :with_streaming, -> { where(:streaming_live => true)}
  scope :with_irekia_coverage, -> { where(:irekia_coverage => true)}

  validates_presence_of :starts_at, :ends_at
  validates_presence_of :organization_id
  validates_length_of   :location_for_gmaps, :maximum => 500, :allow_blank => true

  validate :ends_later_than_it_starts, :if => Proc.new {|event| event.ends_at && event.starts_at}
  # Comprueba que la fecha de finalización es posterior a la de inicio. Se llama en validate
  # def ends_later_than_it_starts
  #   errors.add_to_base "La fecha de fin debe ser posterior a la de inicio" if self.ends_at < self.starts_at
  # end

  validate :location_data_provided
  def location_data_provided
    if self.is_public? && self.place.present?
      unless eloc = EventLocation.find_by_place_and_city_and_address(self.place, self.city, self.location_for_gmaps)
        errors.add_on_empty :city
        errors.add_on_empty :location_for_gmaps
      end
    end
  end

  validate :streaming_room_is_valid
  # Comprueba que se especifica la sala de streaming, en caso de que vaya a haberlo
  def streaming_room_is_valid
    if self.streaming_live
      if !self.stream_flow_id
        errors.add :streaming_room, "está sin especificar. Debes elegir la sala."
      else
        # Comprobar la sala
        if oe = self.overlapped_streaming.detect {|evt| evt.stream_flow_id.eql?(self.stream_flow_id)}
          errors.add :streaming_room, "#{self.stream_flow.title} está ocupada por el evento #{oe.title} (#{oe.pretty_dates})"
        end
        # Comprobar la web de emisión
        # ["irekia"].each do |place|
        #   if self.send("streaming_for_#{place}?") && self.overlapped_streaming.detect {|evt| evt.send("streaming_for_#{place}?")}
        #     errors.add :streaming_for, "#{place.capitalize} está ocupada."
        #   end
        # end
      end
    end
  end

  validate :streaming_for_is_present_if_streaming_live
  def streaming_for_is_present_if_streaming_live
    if self.streaming_live
      sf = STREAMING4.map {|place| self.send("streaming_for_#{place}")}.uniq
      if sf.eql?([0])
        errors.add :streaming_for, "no puede estar vacío. Tienes que elegir por lo menos una opción."
      end
    end
  end

  validate :sync_alertable_and_alert_this_change
  def sync_alertable_and_alert_this_change
    if !self.alertable? && self.alert_this_change
      errors.add :alert_this_change, "no puedes alertar sobre este cambio porque las alertas para este evento están desactivadas"
    end
  end

  # Crea una lista con los sitios donde este evento es visible.
  def visible_in
    show_in = []
    show_in << "private" if self.is_private?
    show_in << "irekia" if self.published?
    return show_in
  end

  # # Si el valor de <tt>val</tt> es <tt>false</tt> el evento es privado y por lo tanto no tiene fecha de publicación
  # def is_private=(val)
  #   if val
  #     self.published_at = nil
  #   end
  # end

  # Indica si el evento está traducido a <tt>lang_code</tt>
  # Los idiomas disponibles son <tt>Document::LANGUAGES</tt>
  def translated_to?(lang_code)
    translated = self.send("title_#{lang_code}").present?
    unless self.send("body_#{I18n.default_locale.to_s}").blank?
      # Los eventos pueden no tener body en ningun idioma
      translated = translated && self.send("body_#{lang_code}").present?
    end
    return translated
  end

  before_save :disable_unnecessary_fields
  before_save :fill_lat_lng_data
  before_save :assign_department_tag  # Defined in document.rb
  before_save :set_to_draft_if_deleted
  before_save :check_user_can_create_this_type_of_event
  before_save :schedule_alerts
  # HT
  # before_save :schedule_tweets
  before_save :sync_streaming_and_room



  def alertable
    if self.is_private?
      val = false
    else
      if self.attributes['alertable'].nil?
        val = true
      else
        val = self.attributes['alertable']
      end
    end
    return val
  end

  # Devuelve <tt>true</tt> si el evento es privado y <tt>false</tt> si no lo es.
  def is_private?
    self.published_at.nil?
  end

  # Lo necesito para el formulario
  def is_private
    is_private? ? "1" : "0"
  end

  # Método auxiliar. Un evento es púbico si no es privado.
  def is_public?
    !self.is_private?
  end

  # Devuelve los nombres de todos los asistemntes: políticos e invitados
  def attendee_names(locale = I18n.locale.to_s)
    speaker4locale =  nil
    if self.speaker.present?
      speaker4locale = self.send("speaker_#{locale}").present? ? self.send("speaker_#{locale}") : self.speaker
    end
    politicians4locale = self.politicians.map {|politician| "#{politician.public_name_and_role(locale)}"}

    (politicians4locale + [speaker4locale]).compact.join(", ")
  end

  # Devuelve el evento en formato ical
  def to_ics(cal, &block)
    if self.deleted?
      cal.add_x_property('METHOD', 'CANCEL')
    else
      cal.add_x_property('METHOD', 'REQUEST')
    end
    cal.event do |event|
      event.uid = "uid_#{self.id}_openirekia"
      event.sequence = self.staff_alert_version
      event.summary = self.title
      event.description = block_given? ? yield[:description] || self.description_for_ics : self.description_for_ics
      event.dtstart =  self.starts_at.getutc.strftime("%Y%m%dT%H%M%SZ")
      event.dtend = self.ends_at.getutc.strftime("%Y%m%dT%H%M%SZ")
      event.location = self.pretty_place
      event.url = yield[:url] if block_given?
      event.created = self.created_at.getutc.strftime("%Y%m%dT%H%M%SZ")
      event.last_modified = self.updated_at.getutc.strftime("%Y%m%dT%H%M%SZ")
      event.dtstamp = Time.zone.now.getutc.strftime("%Y%m%dT%H%M%SZ")
      if self.deleted?
        event.status = "CANCELLED"
      else
        event.status = "CONFIRMED"
      end
    end
  end

  # Descripción formateada para ical
  def description_for_ics
    description = "#{self.organization.name}.\n"
    description << "#{self.attendee_names}.\n"
    description << self.body.to_s.strip_html
    return description
  end

  # El evento puede eliminarse por completo si no hay que notificar sobre su eliminación
  def is_destroyable?
    if (!self.deleted? && self.alerts.sent.count > 0) || (self.deleted? && self.alerts.unsent.count > 0)
      false
    else
      true
    end
  end

  # Si el valor asignado desde el formulario es 0, el evento es público, si no es privado
  def is_private=(val)
    if val.to_s.eql?("0")
      self.published_at = Time.zone.now if self.published_at.blank?
    else
      self.published_at = nil
      self.alertable = false
      self.alert_this_change = 0
    end
    true
  end

  def streaming_places
    self.streaming_for.to_s.split(',')
  end

  def streaming_for?(place)
    self.streaming_places.include?(place)
  end

  # Lista de las webs donde se hará el streaming
  def streaming_for_pretty?
    self.streaming_for.present?
  end

  def streaming_for_pretty(locale=I18n.locale.to_s)
    self.streaming_places.map {|pl| I18n.t("events.#{pl.strip}", :locale => locale)}.to_sentence.gsub("y\sI", "e I").html_safe
  end

  # Tipos de cobertura para el evento.
  def cov_types_pretty(locale=I18n.locale.to_s)
    cov_types = []
    ["irekia_coverage_audio", "irekia_coverage_video", "irekia_coverage_photo", "irekia_coverage_article"].each do |cov_type|
      cov_types << I18n.t("events.#{cov_type}", :locale => locale) if self.send("#{cov_type}?")
    end
    if se = streaming_for_pretty(locale)
      cov_types.push "streaming en #{se}" unless se.blank?
    end
    cov_types.compact
  end




  def self.next4streaming
    # Eventos con streaming que empiezan dentro de 5 horas o menos y no han acabado.
    # self.published.translated.current.with_streaming.map {|evt| evt if  evt.streaming_for?(subsite) && (evt.starts_at <= Time.zone.now + 5.hours) && (evt.ends_at > Time.zone.now)}.compact

    # Eventos con streaming del día. Los que no están traducidos también salen en la lista.
    self.published.current.with_streaming.map {|evt| evt if evt.streaming_for?("irekia")}.compact
  end

  # Devuelve true si el evento se está emitiendo.
  def on_air?
    self.stream_flow && self.stream_flow.on_air? && self.stream_flow.event_id.eql?(self.id)
  end

  # Devuelve true si el streaming del evento está anunciado.
  def announced?
    self.stream_flow && self.stream_flow.announced? && self.stream_flow.event_id.eql?(self.id)
  end

  # Devuelve la lista de eventos que se solapan con <tt>self</tt>
  def overlapped
    Event.where(["(starts_at < ?) AND (ends_at > ?)", self.ends_at, self.starts_at]) - [self]
  end

  # Devuelve la lista de eventos con streaming en directo que se solapan con <tt>self</tt>.
  def overlapped_streaming
    self.overlapped.map {|evt| evt if evt.streaming_live?}.compact
  end

  # Devuelve el status actual del evento: passed, programmed о future.
  def current_status
    status = "future"
    if self.ends_at < Time.zone.now
      status = "passed"
    else
      status = "programmed" if self.starts_at.to_date.eql?(Date.today)
    end
    status
  end

  # Devuelve el streaming status del evento: future, programmed, passed, announced, o live
  def streaming_status
    status = self.current_status
    if self.stream_flow.present?
      status = 'announced' if self.announced?
      status = 'live' if self.on_air?
    else
      status = 'empty'
    end
    status
  end



  # Noticias y videos asignados al evento
  # No se puede usar has_many through con "polymorphic associations".
  def news
    self.related_items.map {|rel| rel.eventable if rel.eventable.is_a?(News)}.compact
  end

  def has_related_news?
    !self.news.blank?
  end

  def related_news
    self.news.first
  end

  def related_news_published
    all = self.news.select {|n| n.published?}

    all.first
  end

  def related_news_title
    @related_news_title ||= self.has_related_news? ? self.related_news.title : nil
  end

  def related_news_id
    self.has_related_news? ? self.related_news.id : nil
  end

  def related_news_title=(search_title)
    if search_title.empty?
      # borramos las relación noticia-evento
      self.news_ids = []
      @related_news_title = 'buscar noticia'
    else
      # sustituimos la noticias asignada al evento por la que corresponde a _search_title_
      if n = News.find_by_title_es(search_title)
        self.news_ids = [n.id]
        @related_news_title = n.title
      end
    end
  end

  def videos
    self.related_items.map {|rel| rel.eventable if rel.eventable.is_a?(Video)}.compact
  end

  def news_ids
    self.related_items.map {|rel| rel.eventable_id if rel.eventable.is_a?(News)}.compact
  end

  def video_ids
    self.related_items.map {|rel| rel.eventable_id if rel.eventable.is_a?(Video)}.compact
  end

  def video_ids=(ids_list)
    self.set_related_items(ids_list, Video)
  end

  def news_ids=(ids_list)
    self.set_related_items(ids_list, News)
  end

  # Periodistas y fotógrafos
  def only_photographers=(val)
    if (val.to_i > 0)
      self.has_photographers = true
      self.has_journalists  = false
    else
      self.has_photographers = false
    end
  end

  def only_photographers
    self.has_photographers? && !self.has_journalists?
  end

  def only_photographers?
    self.only_photographers
  end

  def all_journalists=(val)
    if (val.to_i > 0)
      self.has_photographers = true
      self.has_journalists  = true
    else
      self.has_journalists  = false
    end
  end

  def all_journalists
    self.has_photographers? && self.has_journalists?
  end

  def all_journalists?
    self.all_journalists
  end

  protected
    # No todas las columnas de la tabla documents se utilizan en los eventos,
    # por lo que nos aseguramos de que están vacías.
    # Se llama desde before_save
    def disable_unnecessary_fields
      # self.has_comments = false, en irekia3 sí se pueden comentar los eventos
      # self.comments_closed = true
      self.has_comments_with_photos = false
      self.has_ratings = false
      # self.comments_count = 0
      self.cover_photo_file_name = nil
      self.cover_photo_content_type = nil
      self.cover_photo_file_size = nil
      self.cover_photo_updated_at = nil
    end

    # Los eventos no se pueden eliminar completamente si se han enviado alertas sobre su presencia,
    # hasta que no se envia otra alerta sobre su eliminación. Cuando se marca como eliminado,
    # se pasa a borrador para que deje de aparecer en la parte pública.
    # Se llama desde before_save
    def set_to_draft_if_deleted
      # asi nos aseguramos de que no aparecera en la parte publica
      if self.deleted?
        self.published_at = nil
      end
      return true
    end

    # Los miembros de departamento tienen restrigido el lugar donde pueden publicar eventos (privados o irekia).
    # Aunque el formulario sólo les muestra las opciones que les corresponden, nos aseguramos que no
    # añaden eventos donde no pueden.
    def check_user_can_create_this_type_of_event
      if UserActionObserver.current_user.present?
        yes_he_can = false
        current_user = User.find(UserActionObserver.current_user)
        if (self.is_private? && current_user.can?("create_private", "events")) || \
          (self.is_public? && current_user.can?("create_irekia", "events"))
            yes_he_can = true
        end
        if yes_he_can
          return true
        else
          errors.add(:base, "No puedes crear eventos de este tipo")
          return false
        end
      else
        return true
      end
    end


    # Programa las alertas que se deberán enviar relativas a este evento. Hay dos tipos de alertas
    # * Alertas para periodistas: Cada vez que un campo relevante del evento cambia
    #   (fecha, lugar, visibilidad...), se envía un email notificándolo. Se envían 3 días antes de su comienzo
    # * Alertas para operadores de streaming y responsables de salas: Cuando se confirma el streaming
    #   para un evento, se envían alertas a los operadores de streaming, responsables de sala, y creador
    #   del evento para que preparen lo necesario para el streaming. Se envian 1 día antes de que comiencen
    # * Alertas al creador del evento y el jefe de prensa del departamento del evento cuando cambia el valor
    #   del campo cobertura Irekia (así ellos saben si Irekia va a cubrir el evento o no  y dónde esta el
    #   borrador de la noticia relacionada con el evento)
    #
    # Solo nos preocupamos por las alertas cuando los eventos aún no han pasado. Después, da igual lo que
    # cambien que no avisamos a nadie
    def schedule_alerts
      if self.ends_at && self.ends_at >= Time.zone.now
        # Aviso periodistas
        if (self.alertable_changed? || self.starts_at_changed? || self.ends_at_changed? || self.place_changed? ||  self.published_at_changed? || deleted_changed? || streaming_live_changed? || self.streaming_for_changed?)
          logger.info "Para periodistas: #{self.alertable_changed?} || #{self.starts_at_changed?} || #{self.ends_at_changed?} || #{self.place_changed?} ||  #{self.published_at_changed?} || #{deleted_changed?} || #{streaming_live_changed?} || #{self.streaming_for_changed?}"
          # Borramos las alertas programadas si el evento es privado o nos han pedido que programemos nuevas
          if self.is_private? || self.deleted? || self.alert_this_change
            logger.info "es privado o eliminado o alert this cangeeeeeeeeeeeee"
            EventAlert.delete_all(["spammable_type = ? AND event_id= ? AND sent_at IS NULL", 'Journalist', self.id])
            if self.alertable? || (self.published_at_changed? && self.published_at.nil?)
              # logger.info "Es alertable o lo acabamos de convertir en privado"
              # Si es alertable (por lo tanto, público) alertamos a todos los que corresponda
              # Hay un caso en el que el evento sea alertable == false pero que debamos alertar a los que
              # ya hemos alertado, y es el caso en el que acabamos de convertir el evento en privado. En este
              # caso sólo hay que alertar a los que ya alertamos anteriormente

              self.journalist_alert_version += 1
              event_department_id = self.organization.is_a?(Department) ? self.organization_id : self.organization.department.id
              active_subscriptors_for_this_department = Subscription.active.where("subscriptions.department_id = ?", event_department_id).pluck(:user_id)

              # Debería ser así pero como en spammable_type hemos desglosado en Journalist, etc
              # no funciona porque   "has_many :event_alerts, :as => :spammable" añade la condicion
              # "spammable_type='User'" que no nos vale
              # alerted_subscriptions_for_this_event = Subscription.active.find :all,
              #   :joins => {:journalist => :event_alerts},
              #   :conditions => ["subscriptions.department_id = #{event_department_id}
              #                    AND event_id = ? AND spammable_type = ?", self.id, "Journalist"]

              # alerted_subscriptions_for_this_event = Subscription.active.where(["subscriptions.department_id = #{event_department_id} AND EXISTS (SELECT 1 FROM event_alerts WHERE spammable_id=users.id AND event_id=:event_id AND sent_at IS NOT NULL)", {:event_id => self.id, :spammable_type => "Journalist"}])
              alerted_subscriptions_for_this_event = Subscription.active.joins(:journalist).where(["subscriptions.department_id = ? AND EXISTS (SELECT 1 FROM event_alerts WHERE event_alerts.spammable_id=users.id AND event_alerts.event_id=? AND sent_at IS NOT NULL)", event_department_id, self.id])
              alerted_subscriptors_for_this_event = alerted_subscriptions_for_this_event.map(&:user_id).uniq

              # logger.info "alerted_subscriptors_for_this_event: #{alerted_subscriptors_for_this_event.inspect}"
              alerted_subscriptors_for_this_event.each do |alerted_user_id|
                if self.published_at.nil?
                  alert_send_at = self.starts_at - ALERTS_BEFOREHAND
                else
                  alert_send_at = Time.zone.now
                end
                # Se les alerta tanto si el evento es alertable como si lo acabamos de convertir en privado
                logger.info("Creando alerta para Journalist #{alerted_user_id}")
                self.alerts.build :spammable_id => alerted_user_id, :spammable_type => "Journalist",
                  :version => self.journalist_alert_version, :send_at => alert_send_at,
                  :notify_about => streaming_live_changed? ? 'streaming_live' : nil
              end

              if self.alertable?
                not_alerted_for_this_event = active_subscriptors_for_this_department - alerted_subscriptors_for_this_event
                not_alerted_for_this_event.each do |not_alerted_user_id|
                  if self.is_public?
                    alert_send_at = self.starts_at - ALERTS_BEFOREHAND
                    logger.info("Creando alerta para Journalist #{not_alerted_user_id}")
                    self.alerts.build :spammable_id => not_alerted_user_id, :spammable_type => "Journalist",
                      :version => self.journalist_alert_version, :send_at => alert_send_at,
                      :notify_about => streaming_live_changed? ? 'streaming_live' : nil
                  end
                end
              end
            end
          end
        end

        author_and_department_editors = []
        # Aviso para el creador y el jefe de prensa del departamento sobre cambios en el streaming, las fechas y el sitio
        if self.published_at_changed? || self.starts_at_changed? || self.ends_at_changed? || deleted_changed? || self.place_changed? || streaming_live_changed? || self.streaming_for_changed?
        logger.info("PAra creador y jefe de prensa #{self.published_at_changed?} || #{self.starts_at_changed?} || #{self.ends_at_changed?} || #{deleted_changed?} || #{self.place_changed?} || #{streaming_live_changed?} || #{self.streaming_for_changed?}")
          self.staff_alert_version += 1
          EventAlert.delete_all(["spammable_type = ? AND event_id= ? AND sent_at IS NULL", 'DepartmentEditor', self.id])
          EventAlert.delete_all(["spammable_id = ? AND event_id= ? AND sent_at IS NULL", self.created_by, self.id])
          author_and_department_editors << User.find(self.created_by) if self.created_by
          DepartmentEditor.where({:department_id => self.department.id}).each do |editor|
            author_and_department_editors << editor
          end
        end

        author_and_department_editors.uniq!
        author_and_department_editors.each do |recipient|
          create_alert = false
          last_sent_alert = EventAlert.sent.where(["event_id = ? AND spammable_id = ? AND spammable_type = ?", self.id, recipient.id, recipient.class.to_s]).order("sent_at DESC").first
          if !last_sent_alert
            if self.is_public?
              logger.info "No hay alertas enviadas. Si, creamos"
              create_alert = true
              alert_send_at = self.starts_at - 1.day
            else
              logger.info "Evento sin confirmar o sin publicar. No, no creamos alertas."
            end
          else
            logger.info "Sí, sí creamos"
            create_alert = true
            if self.published_at.nil?
              alert_send_at = self.starts_at - 1.days
            else
              alert_send_at = Time.zone.now
            end
          end
          if create_alert
            logger.info "Creando alerta para #{recipient.class.to_s} #{recipient.id.to_s}"
            self.alerts.build :spammable_id => recipient.id, :spammable_type => recipient.class.to_s,
              :version => self.staff_alert_version, :send_at => alert_send_at,
              :notify_about => streaming_live_changed? ? 'streaming_live' : nil
          end
        end

        streaming_staff = []
        # Aviso para el staff sobre cambios en el streaming, la sala de streaming, las fechas y el sitio
        if self.published_at_changed? || self.starts_at_changed? || self.ends_at_changed? ||
           self.place_changed? || streaming_live_changed? || deleted_changed? ||
           self.stream_flow_id_changed? || self.streaming_for_changed? 
          logger.info("Para staff: #{self.published_at_changed?} || #{self.starts_at_changed?} || #{self.ends_at_changed?} || #{self.place_changed?} || #{streaming_live_changed?} || #{deleted_changed?} ||  #{self.stream_flow_id_changed?} || #{self.streaming_for_changed?}")
          self.staff_alert_version += 1

          EventAlert.delete_all(["spammable_type in ('StreamingOperator', 'RoomManager') AND event_id= ? AND sent_at IS NULL", self.id])

          if self.stream_flow && self.stream_flow.send_alerts?
            streaming_staff += self.stream_flow.room_managers
            streaming_staff += StreamingOperator.all
            # streaming_staff += [User.find(self.created_by)] if self.created_by
          end

          # Avisamos a los responsables de la sala antigua
          if self.stream_flow_id != self.stream_flow_id_was && !self.stream_flow_id_was.nil? && \
             StreamFlow.find(self.stream_flow_id_was).send_alerts?
            streaming_staff += StreamFlow.find(self.stream_flow_id_was).room_managers
            streaming_staff += StreamingOperator.all
            streaming_staff += [User.find(self.created_by)] if self.created_by
          end

          streaming_staff.uniq!
          streaming_staff.each do |recipient|
            create_alert = false
            last_sent_alert = EventAlert.where(["event_id = ? AND spammable_id = ? AND spammable_type = ?", self.id, recipient.id, recipient.class.to_s]).order("sent_at DESC").first
            if !last_sent_alert
              if self.is_public?
                if self.streaming_live?
                  logger.info "No hay alertas enviadas. Si, creamos"
                  create_alert = true
                  alert_send_at = self.starts_at - 1.day
                end
              else
                logger.info "Evento sin confirmar o sin publicar. No, no creamos alertas."
              end
            else
              logger.info "Sí, sí creamos"
              create_alert = true
              if self.published_at.nil?
                alert_send_at = self.starts_at - 1.days
              else
                alert_send_at = Time.zone.now
              end
            end
            if create_alert
              logger.info "Creando alerta para #{recipient.class.to_s} #{recipient.id.to_s}"
              self.alerts.build :spammable_id => recipient.id, :spammable_type => recipient.class.to_s,
                :version => self.staff_alert_version, :send_at => alert_send_at,
                :notify_about => streaming_live_changed? ? 'streaming_live' : nil
            end
          end
        end
      end
      return true
    end


  # HT
  # # Programa el tweet referente a este evento, si está publicado y se muestra en Irekia.
  # # Se tweetea 3 días antes de su comienzo.
  # def schedule_tweets
  #   # Si ha pasado más de un mes de este evento, no lo twitteamos
  #   if self.starts_at && self.starts_at >= 1.month.ago
  #     # Primero borramos los tweets pendientes de este evento, por si ha cambiado la fecha
  #     DocumentTweet.delete_all(["document_id= ? AND tweeted_at IS NULL", self.id])
  #
  #     Event::LANGUAGES.each do |l|
  #       if self.published? && self.translated_to?(l.to_s) && !DocumentTweet.exists?(:document_id => self.id, :tweet_locale => l.to_s)
  #         self.tweets.build(:tweet_account => "irekia_agenda", :tweet_at => self.starts_at - 3.days, :tweet_locale => l.to_s)
  #       end
  #     end
  #   end
  #   return true
  # end

  # Asegura que no tiene sala de streaming si no hay streaming
  def sync_streaming_and_room
    if !self.streaming_live
      self.stream_flow_id = nil
    else
      return true
    end
  end

  # Asigna related_items para cada uno de los ids y el tipo indicado.
  def set_related_items(ids_list, item_type)
    Event.transaction do
      self.related_items.map {|rel| rel if rel.eventable.is_a?(item_type)}.compact.each do |rel|
        if ids_list.include?(rel.eventable_id)
          ids_list.delete(rel.eventable_id)
        else
          rel.destroy
        end
      end
      ids_list.each do |new_id|
        self.related_items.create(:eventable_type => item_type, :eventable_id => new_id)
      end
    end
  end

  # See http://thewebfellas.com/blog/2008/11/2/goodbye-attachment_fu-hello-paperclip#comment-2415
  def attachment_for name
    @_paperclip_attachments ||= {}
    @_paperclip_attachments[name] ||= Attachment.new(name, self, self.class.attachment_definitions[name])
  end


private

  # Si está marcado el checkbox <tt>streaming_live</tt> se guardan los valores seleccionados para <tt>streaming_for</tt>.
  # Si el evento no tiene streaming, <tt>streaming_for</tt> es vacío.
  def set_streaming_for
    if self.streaming_live?
      places = []
      STREAMING4.each do |pl|
        places.push(pl) if self.send("streaming_for_#{pl}?")
      end
      self.streaming_for = places.join(",")
    else
      STREAMING4.each do |pl|
        self.send("streaming_for_#{pl}=",0)
      end
      self.streaming_for = nil
    end

    @streaming_for = self.streaming_for
  end

end
