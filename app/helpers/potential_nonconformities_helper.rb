module PotentialNonconformitiesHelper
  def next_potential_nonconformity_work_paper_code(potential_nonconformity)
    review = potential_nonconformity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_work_papers_in_potential_nonconformities,
      review.try(:created_at))

    code_from_review= review ? review.last_potential_nonconformity_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_potential_nonconformity = potential_nonconformity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_potential_nonconformity].compact.max
  end

  def next_potential_nonconformity_code_for(potential_nonconformity)
    review = potential_nonconformity.control_objective_item.try(:review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_potential_nonconformities, review.try(:created_at))

    review ? review.next_potential_nonconformities_code(code_prefix) :
      "#{code_prefix}1".strip
  end
end
