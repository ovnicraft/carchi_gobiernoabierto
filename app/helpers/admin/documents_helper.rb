# encoding: UTF-8
module Admin::DocumentsHelper
  def pretty_translated(doc, lang_code)
    doc.translated_to?(lang_code) ? "Traducido" : "Sin traducir"
  end
  
  def si_o_no(val)
    val ? t('si') : t('not')
  end

  def dept_select(dept_id, options={})
    txt = ""
    if options[:include_blank]
      txt << content_tag(:option, options[:blank_text] || "#{I18n.t('elige')}...", :value => '')
    end
    Department.grouped_organizations_for_select.each_with_index do |opt_group, index|
      inner = "<option value='#{opt_group[0][1]}' #{"selected" if opt_group[0][1].to_i.eql?(dept_id.to_i)}>#{opt_group[0][0]}</option>".html_safe
      opt_group[1].each do |dept|
        inner << "<option value='#{dept[1]}' #{"selected" if dept[1].to_i.eql?(dept_id.to_i)}>&nbsp;&nbsp;&nbsp;#{dept[0]}</option>".html_safe
      end
      txt << content_tag(:optgroup, inner.html_safe)
    end
    txt.html_safe
  end  

  def area_select(area_tag, options={})
    areas = Area.order('position').collect {|a| [a.name, a.area_tag]}
    if options[:include_blank]
      areas = [["#{I18n.t('elige')}...", ""]] + areas
    end
    options_for_select(areas, area_tag)
  end

  def dept_title(doc)
    doc.organization.is_a?(Department) ? t("organizations.department") : t("organizations.organism")
  end
  
  def dummy_field(txt, obj, method)
    text = ""
    if obj.errors[method.to_sym].present?
      text += content_tag(:span, txt, :class => 'field_with_errors')
      text += content_tag(:span, obj.errors[method.to_sym].to_a.join(", ").gsub(/^(\w)/) {|m| m.upcase}, :class => 'error_message')
    else
      text = txt
    end
    text.html_safe
  end  
  
  # Devuelve el texto que indica dónde está publicado el documento.
  def published_info(doc)
    places = []
    places.push(Settings.site_name) if doc.is_public?
    
    return "#{t('en')} #{places.join(' ' + t('y') + ' ')}"
  end
  
  # # Lista de los políticos con sus cargos públicos
  def politicians_with_roles(doc)
    doc.politicians.map {|politician| content_tag(:span, politician.public_name, :class => 'politician_name')+" "+content_tag(:span, "(#{politician.public_role})", :class => 'politician_role')}.join(", ").html_safe
  end  
  
  # Texto para los asistentes: salen los políticos con sus cargos y los demás asistentes
  # Se usa en los views de AM.
  def politicians_and_speakers_text(doc)
    txt = [politicians_with_roles(doc), doc.speaker].compact.join(", ")
    txt
  end
  
  # Lista de los tags con clase que indica el tipo del tag.
  def tags_with_kind_text(doc, show_legend=true)
    tag = doc.tags.collect { |tag| content_tag(:span, tag.name, :class => "tag #{tag_class(tag)}" )}.join(' ')
    legend = "<br/><span class='tag_legend'><b>Leyenda:</b>
        <span class='tag_departamento'>Departamento</span>
        <span class='tag_area'>Área</span>
        <span class='tag_politico'>Político</span>
        <span class='tag_persona'>Persona</span>
        <span class='tag_entidad'>Entidad</span>
        <span class='tag_oculto'>Oculto</span>
      </span>"
    output = show_legend ? (tag+legend) : tag
    return output.html_safe
  end

  def init_prototype_tooltip
    content_for :head do
     javascript_include_tag('prototype/tooltip')+
     javascript_tag("Event.observe(window, 'load', function(evt){var ttip = new ToolTip('a.link_with_tip')});")
    end
  end

  def can_download_big_photos(document)
    (logged_in? && (User::STAFF + ["Journalist", "Colaborator"]).include?(current_user.class.to_s))
  end
  
  def debate_info(doc)
    doc_type = doc.type.to_s.downcase
    content_tag(:span, t("admin.debates.#{doc_type}_info", :debate => link_to(doc.debate.title, admin_debate_path(doc.debate))).html_safe, :class => "debate_#{doc_type}_notice")
  end

end
