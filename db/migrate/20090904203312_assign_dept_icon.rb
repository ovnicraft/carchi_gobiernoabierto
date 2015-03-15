class AssignDeptIcon < ActiveRecord::Migration
  def self.up
    #
    # Todos los departamentos tienen el icono del Gobierno Vasco.
    # Los demás organismos tendrán su propio icono.
    #
    if icon =  Icon.find(:first, :conditions => {:photo_file_name => 'ej-gv.gif'})
      Department.all.each do |dept|
        dept.update_attribute(:icon_id, icon.id)
      end
    end
  end

  def self.down
  end
end
