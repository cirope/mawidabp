module WeaknessesHelper
  def weakness_priority_text(weakness)
    priorities = parameter_in(@auth_organization.id, :admin_priorities,
      weakness.created_at)

    name_for_option_value priorities, weakness.priority
  end

  def show_weakness_previous_follow_up_dates(weakness)
    dates = weakness.all_follow_up_dates if weakness.being_implemented?
    list = String.new
    out = String.new

    unless dates.blank?
      dates.each { |d| list << content_tag(:li, l(d, :format => :long)) }

      out << link_to_function(t(:'weakness.previous_follow_up_dates'),
        "$('previous_follow_up_dates').showOrHide()")
      
      out << content_tag(:div, content_tag(:ol, list),
        :id => :'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

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

    review ? review.last_weakness_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip
  end

  def next_weakness_code(weakness)
    review = weakness.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_weaknesses, review.try(:created_at))

    review ? review.next_weakness_code(code_prefix) : "#{code_prefix}1".strip
  end
end