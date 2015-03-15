module SearchHelper

  def show_criterio_title(criterio, complete=false)
    output=criterio.title
    if criterio.parent && !complete
      output = output.sub(criterio.parent.title, '')
    end
    aux=[]
    output.split(' AND ').each do |part|
      values=part.split(': ')
      values[1]=values[1..-1].join(': ') if values.size > 2
      case values[0]
      when *Elasticsearch::Base::TRANSLATABLE_FACETS
        value=facet_in_current_locale(values[1])
      when 'type'
        # value = Object.const_defined?(values[1].classify) ? values[1].classify.constantize.model_name.human(:count => 2) : nil
        begin
          value = t("#{values[1]}.title")
        rescue
          value = nil
        end
      when 'date'
        value=I18n.t("search.date#{values[1]}")
      else
        value=values[1]
      end
      if values[0].present?
        if values[0].eql?('keyword')
          aux << value
        else
          aux << "#{I18n.t("search.facets.#{values[0]}")}: #{value}"
        end
      end
    end
    if aux.present?
      h(aux.to_sentence)
    else
      I18n.t('search.todos_los_contenidos')
    end
  end

  def link_to_facets(collection, facet_type, li_class=nil)
    output2=[]
    link_uri='search_index_path'
    collection.each do |facet|
      case facet_type
      when *Elasticsearch::Base::TRANSLATABLE_FACETS
        value=facet_in_current_locale(facet[0])
      when 'type'
        value=facet[0].eql?('orders') ? Order.model_name.human(:count => 2) : t("#{facet[0]}.title")
      when 'date'
        value=I18n.t("search.date#{facet[0]}").mb_chars.capitalize.to_s
      else
        value=facet[0]
      end
      output=[]

      unless value.blank?
        link_params={:key => facet_type, :value => facet[0]}
        if @sort.present? && @sort.eql?('date')
          link_params.merge!(:sort => @sort)
        end
        link_url=send(link_uri, link_params)
        counter = content_tag(:span, "(#{facet[1]})",:class => 'count')
        output << link_to("#{value} #{counter}".html_safe, link_url, :method => :post, :class => 'tag')
        output2 << content_tag(:li, output.join.html_safe, :class => "facet #{cycle('even', 'odd')} #{li_class}")
      end
    end
    output2.join.html_safe
  end

  def facet_in_current_locale(facet)
    position = {'en' => 0, 'es' => 1, 'eu' => 2}
    value=facet.split('|')[position[I18n.locale.to_s]]
    unless value.present?
      value=facet.split('|')[0]
    end
    value
  end

  def highlight_according_to_criterio(text, criterio)
    unless criterio.nil? || criterio.only_title || criterio.title.match(/keyword/).nil?
      keyword = criterio.get_keywords
      output = highlight_according_to_regexp(text, get_highlight_regexp(keyword))
    else
      output = text
    end
    output.html_safe
  end

  def get_highlight_regexp(keyword)
    if keyword.present?
      any_word_in_keyword = Regexp.escape(keyword.escape_for_elasticsearch2.gsub(/\*/, '').split(' ').join('|'))
      Regexp.new(/(#{any_word_in_keyword})(?![^<]*?>)/ix)
    else
      nil
    end
  end
  
  # Consider replacing this with the Rails built in function "highlight"
  def highlight_according_to_regexp(text, reg_exp)
    raw(reg_exp.present? ? text.gsub(reg_exp){|m| "<span class='highlight'>#{m.strip}</span> "} : text)
  end

  def show_search_explanation(item)
    if logged_in? && current_user.is_admin? && item.explanation.present?
      inner = content_tag(:div, link_to("<span>EXPL #{item.score}</span>".html_safe, '#', :class => 'explanation_link'))
      block = content_tag(:div, link_to('Cerrar', "#", :onclick => "$('div#overlay').hide();return false;"), :class => 'close')
      block << content_tag(:div, "SCORE: #{item.score}", :class => 'score')
      block << content_tag(:div, content_tag(:pre, JSON.pretty_generate(item.explanation)))
      inner << content_tag(:div, block.html_safe, :class => 'explanation_content', :style => 'display: none')
      content_tag(:div, inner, :class => 'explanation_link').html_safe
    end
  end

  def show_score(item)
    if logged_in? && current_user.is_admin? && item.score.present?
      content_tag(:span, item.score, :class => 'score')
    end
  end

end
