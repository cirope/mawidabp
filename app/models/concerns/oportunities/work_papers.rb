module Oportunities::WorkPapers
  extend ActiveSupport::Concern

  def work_paper_prefix
    I18n.t 'code_prefixes.work_papers_in_oportunities'
  end

  def last_work_paper_code review = nil
    review ||= control_objective_item&.review

    code_from_review = review ?
      review.last_oportunity_work_paper_code(work_paper_prefix) :
      "#{work_paper_prefix} 0".strip

    code_from_oportunity =
      work_papers.
      reject(&:marked_for_destruction?).
      map(&:code).
      select { |c| c =~ /#{work_paper_prefix}\s\d+/ }.
      sort.
      last

    [code_from_review, code_from_oportunity].compact.max
  end

  def prepare_work_paper work_paper
    work_paper.code_prefix = work_paper_prefix
  end
end
