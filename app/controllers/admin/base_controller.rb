# Métodos comunes para todos los controladores de la administración,
# aquella a la que acceden los Admin.
# 
# Debajo del namespace "admin" estaba la administración completa sólo para administradores generales.
# Paulatinamente los permisos se fueron complicando y ahora otros roles tienen
# permiso para acceder a algunas partes de "admin"
class Admin::BaseController < ApplicationController
  layout 'admin'

  # Comprobamos que el usuario está aprobado
  before_filter :approved_user_required

  # Comprobamos que el usuario tiene permiso de administrador
  before_filter :admin_required

  before_filter :set_current_tab

  # Determina la pestaña activa en el menú de la administración.
  # Cada controller determina el suyo
  def set_current_tab
    @current_tab = :categories
  end
  
  # TOREVIEW: with sprockets running thses assets can't be found
  # :content_css => '/stylesheets/admin/tinymce.css',
  # :content_css => '/stylesheets/admin/style.css',

  # Configuración de las opciones para el editor TinyMCE
  TINYMCE_OPTIONS = {
                  :theme => 'advanced',
                  :language => 'es',
                  :theme_advanced_toolbar_location => 'top',
                  :theme_advanced_statusbar_location => 'none',
                  # :theme_advanced_resizing => true,
                  # :theme_advanced_resize_horizontal => false,
                  # :theme_advanced_blockformats => 'p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp',
                  # :theme_advanced_styles => "Foto izquierda=photo_left;Foto derecha=photo_right",
                  # :theme_advanced_blockformats => "p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp",
                  :theme_advanced_styles => "Subtitular=r01Subtitular;Entradilla=r01Entradilla",
                  :plugins => %w{ table fullscreen paste},
                  # :theme_advanced_buttons1_add => 'removeformat',
                  # :theme_advanced_buttons1 => "bold,italic,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,formatselect,styleselect,|,removeformat,|,pastetext",
                  :theme_advanced_buttons1 => "bold,italic,strikethrough|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,|,removeformat",
                  :theme_advanced_buttons2 => "bullist,numlist,|,outdent,indent,|,undo,redo,|,link,unlink,anchor,image,cleanup,code,|,tablecontrols",
                  :theme_advanced_buttons3 => '',
                  :paste_auto_cleanup_on_paste => true,
                  :paste_remove_styles => true,
                  # No queremos acutes:
                  :entities => '',
                  :relative_urls => false,
                  :extended_valid_elements => "iframe[align<bottom?left?middle?right?top|class|frameborder|height|id|longdesc|marginheight|marginwidth|name|onload|scrolling<auto?no?yes|src|style|title|width]"
                }


  # Filtro que determina si el usuario tiene permiso para modificar los permisos
  def super_user_required
    unless can?('administer', 'permissions')
      flash[:notice] = t('no_tienes_permiso')
      access_denied
    end
  end

end
