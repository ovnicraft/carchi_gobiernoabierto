class CreateEventLocations < ActiveRecord::Migration
  def self.up
    create_table :event_locations do |t|
      t.string :city
      t.string :place
      t.string :address
      t.decimal :lat
      t.decimal :lng
      t.timestamps
    end
    
    [
      ["Ajuria Enea", "Paseo Fray Frascisco", "Vitoria-Gasteiz", 42.841077, -2.679063],
      ["Lehendakaritza", "C/ Navarra 2", "Vitoria-Gasteiz", 42.839135,-2.678053],
      ["Lehendakaritza (sala de prensa)", "C/ Navarra 2", "Vitoria-Gasteiz", 42.839135,-2.678053],
      ["Lehendakaritza (sala de declaraciones)", "C/ Navarra 2", "Vitoria-Gasteiz", 42.839135,-2.678053],
      ["Lakua", "C/ Donostia-San Sebastián, 1", "Vitoria-Gasteiz", 42.859128,-2.686994],
      ["Lakua (sala de prensa)", "C/ Donostia-San Sebastián, 1", "Vitoria-Gasteiz", 42.859128,-2.686994],
      ["Lakua (salón de actos)", "C/ Donostia-San Sebastián, 1", "Vitoria-Gasteiz", 42.859128,-2.686994],      
      ["Gran Vía 85 (salón de actos) (Gobierno Vasco)", "C/ Gran Vía, 85", "Bilbao", 43.264852,-2.944218],
      ["Spri / Sociedades públicas (salón de actos)", "Pza. Bizkaia", "Bilbao", 43.260706,-2.936886],
      ["Edificio Ledo Sanidad (salón de actos)", "", "Bilbao", 43.260815, -2.935781],
      ["Delegación Gobierno Vasco (salón de actos)", "C/ Andía 13", "Donostia-San Sebastián", 43.319761,-1.984373],
      ["Palacio Euskalduna", "Avda. Abandoibarra, 4", "Bilbao", 43.266372,-2.943817],
      ["BEC", "", "Baracaldo", 43.29081,-2.989405],
      ["Parque Tecnológico de Zamudio (Edificio Central)", "", "", 43.289483,-2.859428]
    ].each do |l|
      EventLocation.create(:place => l[0], :address => l[1], :city => l[2], :lat => l[3], :lng => l[4])
    end
  end

  def self.down
    drop_table :event_locations
  end
end
