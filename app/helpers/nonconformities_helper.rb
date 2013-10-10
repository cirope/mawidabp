module NonconformitiesHelper
 def nonconformity_priority_text(nonconformity)
    name_for_option_value nonconformity.class.priorities, nonconformity.priority
  end

  def show_nonconformity_previous_follow_up_dates(nonconformity)
    dates = nonconformity.all_follow_up_dates if nonconformity.being_implemented?
    list = String.new.html_safe
    out = String.new.html_safe

    unless dates.blank?
      dates.each { |d| list << content_tag(:li, l(d, :format => :long)) }

      out << link_to(t('nonconformity.previous_follow_up_dates'), '#', :onclick =>
        "$('#previous_follow_up_dates').slideToggle()")

      out << content_tag(:div, content_tag(:ol, list),
        :id => 'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

      content_tag(:div, out, :style => 'margin-bottom: 1em;')
    end
  end

  def next_nonconformity_work_paper_code(nonconformity, follow_up = false)
    code_prefix = follow_up ?
      I18n.t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      I18n.t('code_prefixes.work_papers_in_nonconformities')

    code_from_review = begin
      review = nonconformity.control_objective_item.review
      review.last_nonconformity_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_nonconformity = nonconformity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_nonconformity].compact.max
  end
end
