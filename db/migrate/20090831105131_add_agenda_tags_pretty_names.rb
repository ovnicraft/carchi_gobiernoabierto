class AddAgendaTagsPrettyNames < ActiveRecord::Migration
  def self.up
    t = Tag.find_or_create_by_sanitized_name_es('_irekia_eventos')
    t.name_es = 'Irekia::Eventos'
    t.name_eu = 'Irekia::Gertaerak'
    t.name_en = 'Irekia::Events'
    t.save
    execute "UPDATE tags set sanitized_name_es='_irekia_eventos', sanitized_name_eu='_irekia_gertaerak', sanitized_name_en='_irekia_events' WHERE name_es='Irekia::Eventos'"
    
    t = Tag.find_or_create_by_sanitized_name_es('_irekia_acciones')
    t.name_es = 'Irekia::Acciones'
    t.name_eu = 'Irekia::Ekintzak'
    t.name_en = 'Irekia::Actions'
    t.save
    execute "UPDATE tags set sanitized_name_es='_irekia_acciones', sanitized_name_eu='_irekia_ekintzak', sanitized_name_en='_irekia_actions' WHERE name_es='Irekia::Acciones'"

    t = Tag.find_or_create_by_sanitized_name_es('_irekia_actos')
    t.name_es = 'Irekia::Actos'
    t.name_eu = 'Irekia::Ekitaldiak'
    t.name_eu = 'Irekia::Ceremonies'
    t.save
    execute "UPDATE tags set sanitized_name_es='_irekia_actos', sanitized_name_eu='_irekia_ekitaldiak', sanitized_name_en='_irekia_ceremonies' WHERE name_es='Irekia::Actos'"
        
  end

  def self.down
  end
end
