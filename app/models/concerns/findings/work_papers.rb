module Findings::WorkPapers
  extend ActiveSupport::Concern

  included do
    has_many :work_papers, -> { order code: :asc }, as: :owner, dependent: :destroy,
      before_add:    [:prepare_work_paper, :check_for_final_review],
      before_remove: :check_for_final_review

    accepts_nested_attributes_for :work_papers, allow_destroy: true
  end

  def prepare_work_paper work_paper
    work_paper.code_prefix ||= I18n.t 'code_prefixes.work_papers_in_weaknesses_follow_up'
  end

  def pdf_cover_items
    control_objective_item.pdf_cover_items + [
      [self.class.model_name.human, title]
    ]
  end
end
