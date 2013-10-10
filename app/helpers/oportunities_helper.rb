module OportunitiesHelper
  def next_oportunity_work_paper_code(oportunity)
    code_prefix = t('code_prefixes.work_papers_in_oportunities')

    code_from_review = begin
      review = oportunity.control_objective_item.review
      review.last_oportunity_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_oportunity = oportunity.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_oportunity].compact.max
  end

  def next_oportunity_code_for(oportunity)
    review = oportunity.control_objective_item.review
    review.next_oportunity_code(oportunity.prefix)
  rescue
    "#{oportunity.prefix}1".strip
  end
end
