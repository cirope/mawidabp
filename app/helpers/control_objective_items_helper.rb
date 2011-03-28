module ControlObjectiveItemsHelper
  def control_objective_relevance_text(control_objective_item)
    relevance = control_objective_item.relevance
    text = name_for_option_value(parameter_in(@auth_organization.id,
        :admin_control_objective_importances,
        control_objective_item.created_at), relevance)

    text.blank? || text == '-' ? text : "#{text} (#{relevance})"
  end

  def control_objective_qualification_text(qualification, created_at)
    text = name_for_option_value(parameter_in(@auth_organization.id,
        :admin_control_objective_qualifications, created_at), qualification)

    text.blank? || text == '-' ? text : "#{text} (#{qualification})"
  end

  def next_control_objective_work_paper_code(control_objective_item)
    code_from_review = next_review_work_paper_code(
      control_objective_item.review)
    code_from_control_objective = control_objective_item.work_papers.reject(
      &:marked_for_destruction?).map(&:code).sort.last

    [code_from_review, code_from_control_objective].compact.max
  end

  def control_objective_weaknesses_summary_headers
    Finding::STATUS.except(:repeated).keys.map do |status|
      content_tag :th, t(:"finding.status_#{status}")
    end.join
  end

  def control_objective_weaknesses_summary_row(control_objective_item)
    Finding::STATUS.except(:repeated).keys.map do |status|
      weaknesses_count = control_objective_item.final_weaknesses.select do |w|
        w.send :"#{status}?"
      end.size

      content_tag :td, weaknesses_count
    end.join
  end
end