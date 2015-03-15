# Clase para las alertas sobre eventos que se envían a periodistas y
# a responsables de sala y operadores de streaming en el caso de eventos con streaming.
class EventAlert < ActiveRecord::Base
  belongs_to :event
  belongs_to :spammable, :polymorphic => true

  validates_presence_of :event_id, :spammable_id

  # FIXME: This trick of setting the value for "spammable_type" manually is not correct since
  # the polymorphic associations assums all records have the value of the parent class.
  # When we do Journalist.find(xxx).event_alerts, the generated query is spammable_type='User'
  # and not spammable_type='Journalist' as I am doing. Therefore, until we don't fix
  # that, we cannot use those methods

  scope :for_journalists, -> { where(["spammable_type='Journalist'"])}
  scope :for_staff, -> { where(["spammable_type<>'Journalist'"])}
  scope :for_streaming_staff, -> { where(["spammable_type in ('StreamingOperator', 'RoomManager')"])}
  scope :sent, -> { where("sent_at IS NOT NULL")}
  scope :unsent, -> { where("sent_at IS NULL")}

  # Indica si este evento ya ha sido enviado anteriormente
  def exists_previous_sent_alert?
    EventAlert.exists?(["event_id = ? and spammable_id = ? and spammable_type = ? and version < ? AND sent_at IS NOT NULL", self.event_id, self.spammable_id, self.spammable_type, self.version])
  end
  
  def first_alert?
    !exists_previous_sent_alert?
  end
end
