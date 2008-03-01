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
    next_review_work_paper_code control_objective_item.review
  end
end