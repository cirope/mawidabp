module FortressesHelper
  def next_fortress_work_paper_code(fortress, follow_up = false)
    code_prefix = follow_up ?
      t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      t('code_prefixes.work_papers_in_fortresses')

    code_from_review = begin
      review = fortress.control_objective_item.review
      review.last_fortress_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_fortress = fortress.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_fortress].compact.max
  end
end
