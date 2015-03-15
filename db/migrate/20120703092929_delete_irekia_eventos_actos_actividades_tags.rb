#
# Eliminar los tags Irekia::Actos, Irekia::Eventos e Irekia::Acciones
# No se usan en irekia3.
#
# eli@efaber.net, 3-07-2012
class DeleteIrekiaEventosActosActividadesTags < ActiveRecord::Migration
  def self.up
    ['_irekia_eventos', '_irekia_actos', '_irekia_acciones'].each do |tag_name|
      if t = Tag.find_by_sanitized_name_es(tag_name)
        t.destroy
      end
    end
    
  end

  def self.down
  end
end
