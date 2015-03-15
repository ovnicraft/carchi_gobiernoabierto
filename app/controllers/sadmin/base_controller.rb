# Métodos comunes para todos los controladores de la administración simplificada,
# aquella a la que acceden los DepartmentMember, DepartmentEditor y StaffChief
# 
# Debajo del namespace "sadmin" estaba la administración simplificada para los roles
# arriba mencionados. Paulatinamente los permisos se fueron complicando y ahora tienen
# permiso para acceder a algunas partes de "admin".
class Sadmin::BaseController < ApplicationController
  layout 'admin'

  # Comprobamos que el usuario está aprobado
  before_filter :approved_user_required, :except => [:myfeed]

  # Cada controller debajo de sadmin tiene un filtro que comprueba los permisos del usuario
  
  before_filter :set_current_tab

  # Determina la pestaña activa en el menú de la administración.
  # Cada controller determina el suyo
  def set_current_tab
    @current_tab = :news
  end

  # Filtro para determinar si el usuario actual tiene permiso para acceder a las paginas de la administración.
  # Debe llamarse desde <tt>before_filter</tt>
  def access_to_sadmin_required
    unless (logged_in? && current_user.is_staff?)
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

  # Filtro para determinar si el usuario actual tiene permiso para acceder a las paginas de la administración de la fototeca.
  # Debe llamarse desde <tt>before_filter</tt>  
  def access_to_photos_required
    unless (logged_in? && can_access?("photos"))
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end  

  #
  # Algunos métodos que se usan en varios de los controladores hijos de Sadmin::Base 
  # 
  def get_sort_order
    @sort_order = params[:sort] ||  "update"
    
    order = nil
    case @sort_order
    when "update"
      order = "featured DESC, updated_at DESC, title_es, published_at DESC"
    when "publish"
      order = "featured DESC, published_at DESC, title_es, updated_at DESC"
    when "title"
      order = "featured DESC, lower(tildes(title_es)), published_at DESC, updated_at DESC"
    end
    
    order
  end 
  
  def get_title_conditions
    conditions = nil
    if params[:q].present?
      conditions = ["lower(tildes(coalesce(title_es, '') || ' ' || coalesce(title_eu, ''))) like ?", "%#{params[:q].tildes.downcase}%"]
    end
    conditions
  end

  def auto_complete_for_document_politicians_tag_list(search_string)
    auto_complete_for_tag_list(search_string, false)
    # @tags.delete_if {|t| !t.kind.eql?('Político')}
    @tags.to_a.delete_if {|t| !t.kind.eql?('Político') || (t.kind.eql?('Político') && t.kind_info.present? && Politician.exists?(t.kind_info.to_i) && Politician.find(t.kind_info.to_i).former?)}
    if @tags.length > 0
      render :inline => "<%= content_tag(:ul, @tags.map {|t| content_tag(:li, t.name)}.join.html_safe) %>"
    else
      render :nothing => true
    end    
  end  
  
  def manage_subtitles_permission_required
     unless can?("manage_subtitles", "news")
       flash[:notice] = t('no_tienes_permiso')
       access_denied
     end
  end
end
