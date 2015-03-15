class SetEventsPublishedat < ActiveRecord::Migration
  def self.up
    # eli@efaber.net (20-06-2012)
    # Hasta ahora la fecha de publicación para los eventos se ponía a Time.zone.now en cada update.
    # Ahora, necesitamos esta fecha para el orden de los eventos en la lista de actividades así que 
    # la ponemos cuando el evento se marca como confirmado.
    # Para poner un valor consistente a piblished_at para los eventos pasados ejecuto el query.
    # Hago el cambio directamente en la base de datos para no cambiar el updated_at y updated_by del evento
    # ni llamar los callbacks
    execute "UPDATE documents SET published_at = starts_at where type='Event' AND state='confirmado' AND (published_at IS NOT NULL) AND (published_at > starts_at)"
  end

  def self.down
  end
end
