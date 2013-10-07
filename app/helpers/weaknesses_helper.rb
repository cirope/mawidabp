module WeaknessesHelper
  def weakness_priority_text(weakness)
    priorities = parameter_in(@auth_organization.id, :admin_priorities,
      weakness.created_at)

    name_for_option_value priorities, weakness.priority
  end

  def show_weakness_previous_follow_up_dates(weakness)
    dates = weakness.all_follow_up_dates if weakness.being_implemented?
    list = String.new.html_safe
    out = String.new.html_safe

    unless dates.blank?
      dates.each { |d| list << content_tag(:li, l(d, :format => :long)) }

      out << link_to(t('weakness.previous_follow_up_dates'), '#', :onclick =>
        "$('#previous_follow_up_dates').slideToggle();return false;")

      out << content_tag(:div, content_tag(:ol, list),
        :id => 'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

      content_tag(:div, out, :style => 'margin-bottom: 1em;')
    end
  end

  def next_weakness_work_paper_code(weakness, follow_up = false)
    review = weakness.control_objective_item.try(:review)
    param_name = follow_up ?
      :admin_code_prefix_for_work_papers_in_weaknesses_follow_up :
      :admin_code_prefix_for_work_papers_in_weaknesses
    code_prefix = parameter_in(@auth_organization.id, param_name,
      review.try(:created_at))

    code_from_review = review ?
      review.last_weakness_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_weakness = weakness.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_weakness].compact.max
  end
end
