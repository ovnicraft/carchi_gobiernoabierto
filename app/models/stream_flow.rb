# Salas de _streaming_. 
#
# Cada sale tiene un título y un código que se usa para generar el HTML necesario para emitir en la web.
class StreamFlow < ActiveRecord::Base
  translates :title
  
  validates_presence_of :title_es
  validates_presence_of :code
  
  # scope :empty_streaming, :conditions => "code = '_empty'"
  scope :not_empty_streaming, -> { where("code != '_empty'").order("position") }
  
  scope :announced, -> { where("announced_in_irekia = 't'")} 
  scope :live, -> { where("show_in_irekia = 't'")}
  
  has_many :room_managements, :class_name => "RoomManagement", :foreign_key => "streaming_id", :dependent => :destroy
  has_many :room_managers, :through => :room_managements
  has_many :events, :class_name => "Event", :foreign_key => "stream_flow_id", :dependent => :nullify

  # El evento que se está emitiendo. Se asign cuando el streaming se anuncia o empieza a emitir.
  belongs_to :event

  # Foto de la sala de streaming. Se muestra al anunciar el evento que se va a emitir.
  has_attached_file :photo, :styles => {:n600 => "600x320>", :n320 => "320x180>", :iphone => "70x70#"},
                    :url  => "/uploads/streaming_rooms/:id/:style/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/streaming_rooms/:id/:style/:sanitized_basename.:extension"
  validates_attachment_size :photo, :less_than => 5.megabytes
  # validates_attachment_content_type :photo, :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/png', 'image/x-png', 'image/gif']  
  validates_attachment_content_type :photo, :content_type => /\Aimage/
  validates_attachment_file_name :photo, :matches => [/png\Z/, /p?jpe?g\Z/, /x-png\Z/, /gif\Z/]

  def self.programmed
    Event.current.with_streaming.map {|evt| evt.stream_flow}.compact.uniq
  end

  def self.live_now
    live_streamings = []
    self.live.map do |sf| 
      if sf.on_air?
        live_streamings << sf.event.present? ? sf.event : sf
      end
    end
    return live_streamings.compact.uniq
  end
  
  # Eventos del día que empiezan dentro de un intervalo de tiempo (en minutos)
  def events_to_be_emitted(time_interval)
    evt = Event.published.with_streaming.where([ "(stream_flow_id = :flow_id) AND (starts_at <= :time_int) AND (ends_at >= :now)", 
                               {
                                 :flow_id => self.id,
                                 :time_int => Time.zone.now + time_interval.minutes,
                                 :now => Time.zone.now
                                }]).order('starts_at')
    evt
  end

  # Eventos del día asignados a la sala de streaming.
  def day_events
    Event.published.with_streaming.where([ "(stream_flow_id = :flow_id) AND (starts_at <= :end) AND (ends_at >= :beginning)", 
                               {
                                 :flow_id => self.id,
                                 :beginning => Time.zone.now.at_beginning_of_day,
                                 :end => Time.zone.now.end_of_day
                                }]).order('starts_at')
  end
  
  # Devuelve el evento que toca emitir dentro de 1 hora o menos.
  def next_event
    self.events_to_be_emitted(60).to_a.first
  end

  # Devuelve el evento que el sistema considera que corresponde al streaming flow en este momento.
  def default_event
    self.next_event || self.day_events.first
  end
  
  # Asigna evento por defecto a la sala de streaming. Primero mira si hay eventos que empiezan dentro de menos de 1 hora.
  # Si no encuentra, coge el primer evento del día si hay eventos del día.
  # Si la sala ya tiene asignado un evento, este no cambia
  def assign_event!
    if self.event.nil? 
      if !self.on_web?
        evt = self.default_event
        self.update_attribute(:event_id, evt.id) if evt
      end
    else
      unless self.event.starts_at.to_date.eql?(Date.today)
        self.event = nil
        self.save
      end
    end
    self.event
  end


  # Indica si el _streaming_ está programado para dentro del tiempo indicado 
  # como <tt>time_interval</tt> (en minutos).
  def to_be_shown?(time_interval=60)
    !self.events_to_be_emitted(time_interval).blank?
  end
  
  # Devuelve <tt>true</tt> si el streaming está anunciado o se está emitiendo en Irekia.
  def on_web?
    self.show_in_irekia? || self.announced_in_irekia?
  end

  # Devuelve true si el streaming se está emitiendo.
  def on_air?
    self.show_in_irekia?
  end  
  
  # Devuelve true si el streaming está anunciado.
  def announced?
    self.announced_in_irekia?
  end
  
  # Devuelve el status del stream flow
  def streaming_status
    status = 'finished'
    status = 'announced' if self.announced?
    status = 'live' if self.on_air?
    status
  end
  
  # Deluelve las fechas del evento la fecha de inicio del streaming si el streaming no tiene evento asignado
  def pretty_dates(locale = I18n.locale)
    self.event.present? ? self.event.pretty_dates(locale) : "#{I18n.localize(self.updated_at.to_date, :format => :long, :locale => locale)}, #{self.updated_at.strftime('%H:%M')}"
  end
  
  # Deluelve las horas del evento o la hora de inicio del streaming si el streaming no tiene evento asignado
  def pretty_hours(locale = I18n.locale)
    self.event.present? ? self.event.pretty_hours(locale) : "#{self.updated_at.strftime('%H:%M')} - "
  end

  # El path que se usa en el image_tag con la foto de la sala de streaming.
  def photo_path
    self.has_photo? ?  self.photo.url(:n600) : "/video/streaming.jpg"
  end

  # Indica si hay foto de la sala.
  def has_photo?
    self.photo_file_name.present?
  end
  
  attr_reader :delete_photo
  # Accessor para borrar la foto de la sala
  def delete_photo=(value)
    self.photo = nil if value.to_i == 1
  end

  # El nombre del fichero con el status del streaming. Se usa para saber si hay que mostrar el player.
  def status_file_name
    "streaming#{self.id}.txt"
  end
  
  def status_file_path
    File.join(Rails.root, '/public/streaming_status', self.status_file_name)
  end
  
  def status_file_url
    "/streaming_status/#{self.status_file_name}"
  end

  # El nombre del fichero con los datos del evento que se emite.
  def event_info_file_name
    "streamed_event#{self.id}.txt"
  end
  
  def event_info_file_path
    File.join(Rails.root, '/public/streaming_status', self.event_info_file_name)
  end
  
  def event_info_file_url
    "/streaming_status/#{self.event_info_file_name}"
  end

  def travelling?
    # Los streamings itinerantes tienen código SIT*
    self.code.match(/^SIT/i)
  end  

  # URL de acceso al streaming para móviles.
  # Sólo para streamings que tienen soporte para este tipo de emisión.
  def mobile_url
    self.mobile_support? ? File.join(Rails.application.config.rtmp_server.sub('rtmp', 'http'), self.code, 'playlist.m3u8') : nil
  end  
end
