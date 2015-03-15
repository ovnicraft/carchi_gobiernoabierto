# Clase para los permisos individuales de los usuarios #User. En principio 
# es para los DepartmentMember, pero se pueden usar para todo tipo de #User
# Estas son las opciones disponibles en este momento:
#     module       |    action       | Que puede hacer
#  ----------------+-----------------+-------------------------
#  news            | create          | Crear noticias
#  news            | edit            | Modificar y traducir noticias
#  news            | complete        | Modificar, traducir y modificar la informacion adicional de noticias (multimedia)
#  news            | export          | Exportar noticias para importar en euskadi.net
#  comments        | edit            | Moderar comentarios
#  comments        | official        | Responder comentarios de manera oficial
#  events          | create_private  | Eventos de uso interno del Gobierno
#  events          | create_irekia   | Eventos para Irekia
#  permissions     | administer      | Repartir permisos entre el resto de usuarios
#  recommendations | rate            | Puede marcar las noticias relacionadas como acertadas o no
#  headlines       | approve         | Puede aprobar los titulares importados desde Entzumena. También puede editar el area y el idioma. 

class Permission < ActiveRecord::Base
  belongs_to :user
  
  attr_accessor :editable
  
  def editable
    @editable.nil? ? true : @editable
  end
  
  validates_uniqueness_of :action, :scope => [:user_id, :module]
  
  after_save :reset_official_commenters
  after_destroy :reset_official_commenters
  
  private
  
  def reset_official_commenters
    if self.action.eql?('official') || self.action_was.eql?('official')
      User.official_commenters = nil
    end
  end
  
end
