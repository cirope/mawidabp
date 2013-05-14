module FortressesHelper
  def next_fortress_work_paper_code(fortress, follow_up = false)
    review = fortress.control_objective_item.try(:review)
    param_name = follow_up ?
      :admin_code_prefix_for_work_papers_in_weaknesses_follow_up :
      :admin_code_prefix_for_work_papers_in_fortresses
    code_prefix = parameter_in(@auth_organization.id, param_name,
      review.try(:created_at))

    code_from_review = review ?
      review.last_fortress_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_fortress = fortress.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_fortress].compact.max
  end
end
