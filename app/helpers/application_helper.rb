# encoding: UTF-8
module ApplicationHelper  
  include ActsAsTaggableOn::TagsHelper
  include WhiteListHelper
  include LaterDude::CalendarHelper
  
  # Example: <%= link_to_in_every_locale "Nuevo documento", "new_admin_document_path", :content_tag => :li %>
  def link_to_in_every_locale(text, link, options = {})
    options.reverse_merge(:content_tag => :li)
    output = ""
    locales.each_pair do |code, lang|
      output << content_tag(options[:content_tag], link_to("#{text} en #{lang}", self.send(link, {:lang => code})))
    end
    return output
  end
  
  # Example: 
  # <% for_every_locale do |code, lang| %>
  #   <%= content_tag(:li, link_to("Nuevo documento en #{lang}", self.send("new_admin_document_path", {:lang => code}))) %>
  # <% end %>  
  def for_every_locale(*args, &block)
    locales.each_pair do |code, lang|
      yield(*args + [code, lang])
    end    
  end
  
  def change_locale_link(locale)
    url = if request.url.match(/\/#{I18n.locale}\/*/)
      request.url.sub(/\/#{I18n.locale}\//, "/#{locale}/").sub(/\/#{I18n.locale}$/, "/#{locale}")
    elsif request.url.match(/[?]locale=#{I18n.locale}/)
      request.url.sub(/[?]locale=#{I18n.locale}/, "?locale=#{locale}")
    else  
      request.url + locale
    end
    link_to_unless(I18n.locale.to_s.eql?(locale), locale, url)
  end

  # Not used
  def body_class
    @body_class || ""
  end

  def homepage?
    controller_name.eql?('site') && action_name.eql?('show')
  end

  def block_to_partial(partial_name, options={}, &block)
    options.merge!(:block => block.present? ? capture(&block) : '') 
    concat(render(:partial => partial_name, :locals => options))
  end
  
  def carousel_widget(options = {}, &block)
    block_to_partial('/shared/carousel', options, &block) 
  end 
  
  def image_tip(options={})
    content_tag(:div, '&nbsp;'.html_safe, :class => 'balloon-top') +
                      content_tag(:div, ((options[:date] ? content_tag(:span, I18n.localize(options[:date], :format => :long), :class => 'date') : "") +
                                        content_tag(:span, h(options[:title]))).html_safe, 
                                        :class => 'balloon-bottom')
  end

  # Google Analytics's specific functions
  def ga_get_current_section
    sname = nil
    
    case controller.controller_name
    when 'events'
      sname ='Agenda'
    when 'videos', 'news', 'albums'
      sname = 'Multimedia'
    when 'site'
      sname = 'Redes y blogs' if params[:controller].eql?('snetwork')
    when 'proposals'
      sname = 'Propuestas ciudadanas'
    when 'categories'
      if @category && (@category.name_es.match('Multimedia') || @category.name_es.match('Hemeroteca'))
        sname = 'Multimedia'
      end
    when 'pages'
      if @flash_page
        sname = "Qué es irekia"
      end
    end
    sname
  end

  def ga_custom_vars
    cvars = []
    cvars.push "_gaq.push(['_setCustomVar',1,'Acceso','Ciudadanos',3]);"
    
    current_section = ga_get_current_section()
    cvars.push "_gaq.push(['_setCustomVar',2,'Seccion','#{current_section.tildes.gsub(/\s+/, '_')}', 3]);" if current_section        
    
    cvars.join("\n")
  end
  # /GA functions
  
  # WhiteListHelper.attributes.merge %w(id class style)
  #WhiteListHelper.tags.delete 'div'
  
  # def inline_error_messages(*objects)
  #   messages = objects.compact.map {|o| o.errors.full_messages.flatten}
  #   render :partial => '/shared/inline_error_messages', :object => messages unless messages.empty?
  # end
  
  # Returns true if a fetured video o streaming is defined.
  def video_or_streaming?
    @featured_video.present? || @streaming.present? || @announced_streaming.present?
  end  
  
  def header_links
    {"es" => [
      {:text => t('site.Contacto'), :url => contact_site_path}
     ],
     "eu" => [
      {:text => t('site.Contacto'), :url => contact_site_path}
     ]
    }
  end
  
  def enet_contact_form_lang_code(lang)
    Document::LANGUAGES.index(lang) + 1
  end
  
  # Link to Guia de la Comunicación http://gida.irekia.euskadi.net
  def show_gc_link_if_present(item)
    if item.gc_link.present?
      link_to(image_tag('gc-icon.gif'), item.gc_link, :rel => 'external', :class => "gc_link", :title => t("site.ver_en_gc").html_safe)
    else
      ""
    end
  end

  # Request from an iPhone or iPod touch? (Mobile Safari user agent)
  def iphone_user_agent?
    request.env["HTTP_USER_AGENT"] && !request.env["HTTP_USER_AGENT"].match(/iPhone/).nil?
  end

  def android_user_agent?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/Android/i]
  end

  def ipad_user_agent?
    # Mozilla/5.0(iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) 
    # Version/4.0.4 Mobile/7B314 Safari/531.21.10
    request.env["HTTP_USER_AGENT"] && !request.env["HTTP_USER_AGENT"].match(/(iPad)/i).nil?
  end  

  def mobile_user_agent?
    ipad_user_agent? || iphone_user_agent? || floki_user_agent?
  end
  
  def connected_from_lan?
    request.remote_ip.match(/10\.(\d+\.){2}\d+/)
  end

  def double_quote_quote(text)
    text.gsub("'", "\"")
  end
  
  def controller_for(document)
    document.class.to_s.downcase.pluralize
  end

  def init_jquery_tools_scrollable
    content_for :js_data do
      javascript_include_tag("jquery.tools.scrollable.min")
    end 
  end
  
  def init_jquery_lightbox
    content_for :js_data do
      stylesheet_link_tag('jquery.lightbox.css') +
      javascript_include_tag('jquery.lightbox.custom.min.js')
    end
  end      
  
  def init_photo_video_viewer(lightbox=:false)
    content_for :css_data do
      stylesheet_link_tag("public/photo_video_viewer") + (lightbox.eql?(:true) ? stylesheet_link_tag('lib/jquery.lightbox') : '')
    end
    content_for :js_data do
      javascript_include_tag("public/photo_video_viewer") + (lightbox.eql?(:true) ? javascript_include_tag('lib/jquery.lightbox.custom.min') : '')
    end 
  end            
       
  def init_bootstrap_select
    content_for :css_data do
      stylesheet_link_tag('bootstrap-select.min')
    end
    content_for :js_data do
      javascript_include_tag('bootstrap-select.min')
    end
  end

  def init_jquery_videosub
    content_for :js_data  do
      javascript_include_tag('jquery.videosub.min') +
      javascript_tag do
        "$(document).ready(function(){
          Irekia.hostWithPort = 'http://#{request.host_with_port}';
          $('video').videoSub();
        });"
      end
    end
  end

  def avatar(item, opts = {})
    size = opts[:size] || :thumb_70

    # if item.respond_to?(:avatar) && item.avatar.present? && !item.avatar.url.eql?("/images/icons/faceless_avatar.png")
    #   avatar_image = image_tag(item.avatar.url(size)) + content_tag(:div, " ", :class => :ieframe)      
    # else
    #   avatar_image = image_tag "icons/faceless#{ "_#{size}" unless size.blank? }_avatar.png", :class => "avatar #{size}", :title => t('unknown_user')      
    # end
    
    if item.respond_to?(:photo)
      avatar_image = image_tag(item.photo.url(size)) + content_tag(:div, " ", :class => :ieframe)
    else
      avatar_image = image_tag(asset_path("default/faceless_avatar_#{ size unless size.blank? }.png"), :class => "avatar #{size}", :title => t('unknown_user'))
    end
    
    avatar_html = case 
                  when item.is_a?(Politician)
                    link_to(avatar_image, politician_url(item), :class => "avatar #{size}")
                  when item.class.superclass.to_s.eql?('User') && !item.new_record?
                    avatar_url = (item == current_user) ? account_path : user_url(item)
                    link_to(avatar_image, avatar_url, :class => "avatar #{size}")
                  else
                    link_to(avatar_image, '#', :class => "avatar #{size}")
                  end
    
    avatar_html
  end
  
  def class_for_window_login
    logged_in? ? '' : 'login-required'
  end

  def translation_missing_info
    content_tag(:div, t('shared.traslation_missing'), :class => "alert alert-info traslation_missing")
  end
  
  def notifications_count
    logged_in? ? current_user.notifications.pending.count : 0
  end
  
  # Please, preserve this order!
  def follow_irekia_links
    Settings.social_networks.to_a.delete_if {|s| s[1].blank?}
  end

  def show_context
    !(@area.present? || @politician.present? || @user.present? || @debate.present?)
  end

  def context_partial(context, prefix)
    "#{prefix}#{context.present? ? "_#{context.class.to_s.downcase}" : ''}"
  end

  def section_heading_with_context(wrapper, text, context=nil)
    if context
      text << " #{t('shared.from_context', :name => context.public_name)}"
    end  
    content_tag(wrapper, text, :class => 'section_heading')
  end

  def date_in_distance(date)
    if date && date < 7.days.ago
      I18n.l(date.to_date, :format => :long)
    elsif date
      I18n.t('shared.hace_time', :time => distance_of_time_in_words_to_now(date))
    else 
      ''
    end
  end

  def render_date(date='-')
    date_text = (date.is_a?(Time) || date.is_a?(Date)) ? I18n.l(date.to_date, :format => :long) : date
    output = []
    output << content_tag(:i, '', :class => 'ico_date')
    output << content_tag(:div, date_text, :class => 'meta_text')
    content_tag(:div, output.join.html_safe, :class => 'date meta_article')
  end
  
  # NOT USED
  # def handheld_check
  #   {'iphone' => 'iPhone', 'android' => 'Android'}.each do |handheld_type, pretty_type|
  #     if self.send("#{handheld_type}_user_agent?")
  #       content_for :handheld_warning do
  #         content_tag(:p, t('site.usas_device', :device => pretty_type, :link => link_to(t('site.version_optimizada'), self.send("#{handheld_type}_path"))), :class => "mobile_warning")
  #       end
  #     end
  #   end
  # end

  def render_loading_spinner(type=nil)
    output = []
    output << image_tag(asset_path('ajax-loader.gif'))
    output << content_tag(:span, t("#{type}.loading"), :class => 'spinner_text') if type.present?
    content_tag(:div, output.join.html_safe, :class => 'spinner')
  end

  def show_see_more_heading(type, context=nil)
    output = t("#{type}.more")
    output << " #{t('shared.from_context', :name => context.public_name)}" if context
    output
  end

  def locale_es_or_eu
    I18n.locale.to_s.eql?('eu') ? 'eu' : 'es'
  end

  def item_qr_code(item)
    url = send("#{item.class.to_s.downcase}_url", :id => item.id)
    unless File.exists?(item.qr_code_path)
      # Create qrcode if doesn't exist
      FileUtils.mkdir_p(File.dirname(item.qr_code_path))
      system "qrencode -o #{item.qr_code_path} #{url}"
    end
    image_tag(item.qr_code_url)
  end
  
  def base_url
    if request
      "#{request.protocol}#{request.host_with_port}"
    else
      "http://#{ActionMailer::Base.default_url_options[:host]}"
    end
  end

  def embed_layout?
    @embed_layout
  end

  def error_messages(item)
    unless item.errors.empty?
      errors=item.errors.full_messages.uniq
      output = ''
      output << content_tag(:h2, t('activerecord.errors.template.header', :count => errors.size, :model => item.class.model_name))
      # output << content_tag(:p, t('activerecord.errors.template.body'))
      errors.each do |text|
        output << content_tag(:ul, content_tag(:li, text).html_safe)
      end
      content_tag(:div, output.html_safe, :id => 'errorExplanation', :class => 'errorExplanation') 
    end  
  end
  
end
