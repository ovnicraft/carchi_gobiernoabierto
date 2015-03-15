class CreateDepartments < ActiveRecord::Migration
  
  def self.up    
    create_table :departments do |t|
      t.string :name_es, :name_eu, :name_en
      t.timestamps
    end
    Department.create(:name_es => "Gobierno Vasco", :name_eu => "Eusko Jaurlaritza", :name_en => "Basque Government")
  end

  def self.down
    drop_table :departments
  end
end
