# encoding: UTF-8
module Admin::AdminHelper

  def menu_link_class(tab)
    @current_tab.eql?(tab) ? "active" : "passive"
  end
  
  def admin_section_name
    titles = {:menus => 'Misc', :depts => t('admin.menu.departamentos'), :users => t('admin.menu.usuarios'),
              :stats => t('admin.menu.estadisticas'), :news => t('admin.menu.noticias'),
              :events => t('admin.menu.agenda'), :videos => t('admin.menu.web_tv'), 
              :photos => t('admin.menu.fototeca'), :pages => t('admin.menu.paginas'),
              :links => t('admin.menu.enlaces'), :posts => 'Blog', :proposals => t('admin.menu.propuestas'),
              :stream_flows => t('admin.menu.streaming'),
              :users => 'Usuarios'
              }
     text = titles[@current_tab] || t("admin.menu.#{@current_tab}")
     text = nil if text.eql?(@title)
     text
  end

  def multimedia_content_dir_format
    'Sólo letras sin tildes, números y "_". "/" para indicar directorios.'
  end

  def file_name_for_path(path)
    Pathname.new(path).basename
  end
  
  def convert_relative_urls_to_absolute(text)
    e = "http://#{ActionMailer::Base.default_url_options[:host]}"
    # e = "#{request.protocol}#{request.host_with_port}"
    text.sub(/href=([\"\'])\//, "href=\\1#{e}/")
  end

end
