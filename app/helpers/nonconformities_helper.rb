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
        "$('#previous_follow_up_dates').slideToggle();return false;")

      out << content_tag(:div, content_tag(:ol, list),
        :id => 'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

      content_tag(:div, out, :style => 'margin-bottom: 1em;')
    end
  end

  def next_nonconformity_work_paper_code(nonconformity, follow_up = false)
    review = nonconformity.control_objective_item.try(:review)
    code_prefix = follow_up ?
      t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      nonconformity.work_paper_prefix

    code_from_review = review ?
      review.last_nonconformity_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    work_paper_codes = nonconformity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }

    last_code = work_paper_codes.map do |code|
      code.match(/\d+\Z/)[0].to_i if code =~ /\d+\Z/
    end.compact.sort.last.to_i

    next_number = [code_from_review.match(/\d+\Z/)[0].to_i, last_code].max

    "#{code_prefix} #{next_number}"
  end
end
