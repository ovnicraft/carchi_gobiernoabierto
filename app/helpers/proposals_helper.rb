module ProposalsHelper

  def participation_result_percentage(item, target=:list)
    result = item.percentage_to_text
    output = []
    if !item.participation.zero? || (target.eql?(:avatar) && item.participation.zero?)
      output << content_tag(:span, "#{item.send('percent_' + result)} %", :class => 'percentage')
      output << content_tag(:span, t("proposals.#{result}"), :class => 'percentage_text')
    end
    if target.eql?(:votes)
      output = [content_tag(:div, output.join.html_safe, :class => 'percentage_total')]
    end
    unless target.eql?(:avatar)
      inner = t("votes.count", :count => item.participation)
      if item.participation > 0 && target.eql?(:votes)
        inner << " (" + content_tag(:span, content_tag(:span, item.n_in_favor,:class => 'in_favor') + "/" + content_tag(:span, item.n_against,:class => 'against')) + ") "
      end
      output << content_tag(:span, inner.html_safe, :class => 'participation')
    end
    output.join(' ').html_safe
  end

  def render_participation_result_percentage(item, target=:list)
    content_tag(:div, participation_result_percentage(item, target), :class => "result #{item.percentage_to_text} #{target.eql?(:votes) ? 'span3' : ''}")
  end

  def render_zuzenean_banner_advice
    inner = []
    inner << content_tag(:div, t('proposals.advice_zuzenean'), :class => 'advice')
    inner << content_tag(:div, link_to(image_tag("banners/zuzenean_#{I18n.locale.to_s}.jpg"), "http://www.zuzenean.euskadi.net/s68-home/#{locale_es_or_eu}", :rel => 'external'), :class => 'banner_image')
    content_tag(:div, inner.join.html_safe, :class => 'banner_aside zuzenean')
  end

  def icon_for_proposal(proposal)
    link_to participation_result_percentage(proposal, :avatar), proposal_path(proposal), :class => "result_icon #{proposal.percentage_to_text}"
  end

  def answer_text(proposal, url_or_anchor="anchor")
    official_comments = proposal.comments.official.approved
    if official_comments.size > 0
      first_official_comment = official_comments.last # los comentarios están ordenados al revés
      href = (url_or_anchor.eql?('url') ? proposal_path(proposal) : '') + "#comment_#{first_official_comment.id}"
      link_to t('proposals.answered', :time => distance_of_time_in_words(proposal.published_at, first_official_comment.published_at)), href, :class => "answered"
    else
      content_tag :span, t('proposals.not_answered'), :class => "not_answered"
    end
  end

end
