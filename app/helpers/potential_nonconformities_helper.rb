module PotentialNonconformitiesHelper
  def next_potential_nonconformity_work_paper_code(potential_nonconformity)
    code_prefix = t('code_prefixes.work_papers_in_potential_nonconformities')

    code_from_review = begin
      review = potential_nonconformity.control_objective_item.review
      review.last_potential_nonconformity_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_potential_nonconformity = potential_nonconformity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_potential_nonconformity].compact.max
  end

  def next_potential_nonconformity_code_for(potential_nonconformity)
    review = potential_nonconformity.control_objective_item.review
    review.next_potential_nonconformities_code(potential_nonconformity.prefix)
  rescue
    "#{potential_nonconformity.prefix}1".strip
  end
end
