module OportunitiesHelper
  def next_oportunity_work_paper_code(oportunity)
    review = oportunity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_work_papers_in_oportunities,
      review.try(:created_at))

    review ? review.last_oportunity_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip
  end

  def next_oportunity_code_for(oportunity)
    review = oportunity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_oportunities, review.try(:created_at))

    review ? review.next_oportunities_code(code_prefix) :
      "#{code_prefix}1".strip
  end
end