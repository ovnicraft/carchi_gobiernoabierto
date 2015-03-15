class CreateOrder < ActiveRecord::Migration
  def self.up
    create_table :orders, :force => true do |t|
      t.date :fecha_bol
      t.date :fecha_disp
      t.string :dept_es, :limit => 500
      t.string :dept_eu, :limit => 500      
      t.string :materias_es, :limit => 500      
      t.string :materias_eu, :limit => 500            
      t.string :no_bol
      t.string :no_disp
      t.string :no_orden
      t.string :rango_es
      t.string :rango_eu      
      t.string :seccion_es
      t.string :seccion_eu      
      t.text :titulo_es
      t.text :titulo_eu      
      t.text :texto_es
      t.text :texto_eu  
      t.text :ref_ant
      t.text :ref_pos
      t.text :vigencia
      t.timestamps
    end
  end

  def self.down
    drop_table :orders
  end
end