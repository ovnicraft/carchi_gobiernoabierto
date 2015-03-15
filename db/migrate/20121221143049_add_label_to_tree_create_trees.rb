class AddLabelToTreeCreateTrees < ActiveRecord::Migration
  def self.up
    add_column :trees, :label, :string
    Tree.find_by_name_es('Canales WebTV').update_attribute(:label, 'web_tv')
    Tree.find_by_name_es('Menu Agencia').update_attribute(:label, 'ma_menu')    
    Tree.find_by_name_es('Fototeca').update_attribute(:label, 'gallery')        
    Tree.find_by_name_es('Menu').update_attribute(:label, 'menu')            
    
    Tree.create(:name_es => 'Inicio', :name_eu => 'Hasiera', :name_en => 'Home', :label => 'navbar_left')    
    Tree.create(:name_es => 'Qué es Irekia', :name_eu => 'Zer da Irekia?', :name_en => 'About Irekia', :label => 'navbar_right')    
  end

  def self.down                       
    Tree.find_by_name_es('Inicio').destroy if Tree.find_by_name_es('Inicio')
    Tree.find_by_name_es('Qué es Irekia').destroy if Tree.find_by_name_es('Qué es Irekia')    

    remove_column :trees, :label
  end
end
