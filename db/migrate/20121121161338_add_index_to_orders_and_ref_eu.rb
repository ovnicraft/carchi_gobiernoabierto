class AddIndexToOrdersAndRefEu < ActiveRecord::Migration
  def self.up
    add_index :orders, :no_orden
    rename_column :orders, :vigencia, :vigencia_es
    rename_column :orders, :ref_ant, :ref_ant_es    
    rename_column :orders, :ref_pos, :ref_pos_es        
    add_column :orders, :vigencia_eu, :text
    add_column :orders, :ref_ant_eu, :text    
    add_column :orders, :ref_pos_eu, :text        
  end

  def self.down                 
    remove_column :orders, :ref_pos_eu
    remove_column :orders, :ref_ant_eu    
    remove_column :orders, :vigencia_eu
    rename_column :orders, :ref_pos_es, :ref_pos
    rename_column :orders, :ref_ant_es, :ref_ant
    rename_column :orders, :vigencia_es, :vigencia        
    remove_index :orders, :no_orden
  end
end
