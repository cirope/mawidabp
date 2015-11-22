module PotentialNonconformitiesHelper
  def next_potential_nonconformity_work_paper_code(potential_nonconformity)
    review = potential_nonconformity.control_objective_item.try(:review)
    code_prefix = potential_nonconformity.work_paper_prefix

    code_from_review= review ? review.last_potential_nonconformity_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    work_paper_codes = potential_nonconformity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }

    last_code = work_paper_codes.map do |code|
      code.match(/\d+\Z/)[0].to_i if code =~ /\d+\Z/
    end.compact.sort.last.to_i

    next_number = [code_from_review.match(/\d+\Z/)[0].to_i, last_code].max

    "#{code_prefix} #{next_number}"
  end

  def next_potential_nonconformity_code_for(potential_nonconformity)
    review = potential_nonconformity.control_objective_item.try(:review)
    code_prefix = potential_nonconformity.prefix

    review ? review.next_potential_nonconformities_code(code_prefix) :
      "#{code_prefix}1".strip
  end
end
