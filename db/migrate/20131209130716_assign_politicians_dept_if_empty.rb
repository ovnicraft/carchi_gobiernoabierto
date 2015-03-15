class AssignPoliticiansDeptIfEmpty < ActiveRecord::Migration
  def self.up
    # Areas:
    # [[7, "Lehendakaritza"], 
    # [5, "Empleo y Políticas Sociales"], 
    # [8, "Educación, Política Lingüística y Cultura"], 
    # [1, "Seguridad"], 
    # [9, "Salud"], 
    # [12, "Medio Ambiente y Política Territorial"], 
    # [14, "Administración Pública y Justicia"], 
    # [17, "Hacienda y Finanzas"],
    # [6, "Desarrollo Económico y Competitividad"]]
    #
    
    # Departamentos:
    # [[68, "Gobierno Vasco X leg"],
    # [65, "Lehendakaritza X leg"], 
    # [63, "Salud X leg"], 
    # [64, "Medio Ambiente y Política Territorial X leg"], 
    # [57, "Administración Pública y Justicia X leg"], 
    # [60, "Hacienda y Finanzas X leg"], 
    # [62, "Seguridad X leg"], 
    # [58, "Desarrollo Económico y Competitividad X leg"], 
    # [59, "Empleo y Políticas Sociales X leg"], 
    # [61, "Educación, Política Lingüística y Cultura X leg"]]
    dept4area = {
      "Lehendakaritza" => Department.find_by_name_es("Lehendakaritza X leg"),
      "Empleo y Políticas Sociales" => Department.find_by_name_es("Empleo y Políticas Sociales X leg"),
      "Educación, Política Lingüística y Cultura" => Department.find_by_name_es("Educación, Política Lingüística y Cultura X leg"),
      "Seguridad" => Department.find_by_name_es("Seguridad X leg"),
      "Salud" => Department.find_by_name_es("Salud X leg"),
      "Medio Ambiente y Política Territorial" => Department.find_by_name_es("Medio Ambiente y Política Territorial X leg"),
      "Administración Pública y Justicia" => Department.find_by_name_es("Administración Pública y Justicia X leg"),
      "Hacienda y Finanzas" => Department.find_by_name_es("Hacienda y Finanzas X leg"),
      "Desarrollo Económico y Competitividad" => Department.find_by_name_es("Desarrollo Económico y Competitividad X leg")
    }
    
    dept_gv = Department.find_by_name_es("Gobierno Vasco X leg")
    Politician.approved.where("(department_id IS NULL) OR (department_id =  #{dept_gv.id})").each do |politician|
      if politician.areas.present?
        area_name = politician.areas.first.name_es
        if dept = dept4area[area_name] 
          p "Cambiando el dept de político #{politician.id} de #{politician.department_id} a #{dept.id}"
          politician.update_attribute(:department_id, dept.id)
        else
          p "No hay departamento para el área: #{area_name}, político #{politician.id}"
        end
      else
        p "No hay area para el político #{politician.id}"
      end
    end
    
  end

  def self.down
  end
end
