module DebatesHelper

  def render_debate_stage_dates(stage, joiner="<br/>")
    output = [I18n.l(stage.starts_on, :format => :long)]
    output << [I18n.l(stage.ends_on, :format => :long)]
    content_tag(:div, output.join(joiner).html_safe, :class => 'stage_date')
  end

  def render_debates_legal_advice
    inner = []
    inner << content_tag(:li, t('debates.legal_advice1'))
    inner << content_tag(:li, t('debates.legal_advice2'))
    inner << content_tag(:li, t('debates.legal_advice3'))
    content_tag(:div, content_tag(:strong, t('site.legal_advice')) + content_tag(:ul, inner.join.html_safe), :class => 'legal_advice')
  end

  def debate_caption_class(debate)
    if debate.title.length <= 57
      'bottom_small'
    elsif debate.title.length > 57 && debate.title.length < 90
      'bottom_medium'
    else
      'bottom_large'
    end
  end

end
