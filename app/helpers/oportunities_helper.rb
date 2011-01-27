module OportunitiesHelper
  def next_oportunity_work_paper_code(oportunity)
    review = oportunity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_work_papers_in_oportunities,
      review.try(:created_at))

    code_from_review= review ? review.last_oportunity_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_oportunity = oportunity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_oportunity].compact.max
  end

  def next_oportunity_code_for(oportunity)
    review = oportunity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_oportunities, review.try(:created_at))

    review ? review.next_oportunities_code(code_prefix) :
      "#{code_prefix}1".strip
  end
end