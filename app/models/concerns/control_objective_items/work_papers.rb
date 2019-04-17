module ControlObjectiveItems::WorkPapers
  extend ActiveSupport::Concern

  included do
    before_validation :set_proper_parent

    has_many :work_papers, -> { order(code: :asc) }, as: :owner,
      dependent: :destroy,
      before_add: [:check_for_final_review, :prepare_work_paper],
      before_remove: :check_for_final_review

    accepts_nested_attributes_for :work_papers, allow_destroy: true
  end

  def pdf_cover_items
    [
      [BestPractice.model_name.human, best_practice.name],
      [ProcessControl.model_name.human, process_control.name],
      [self.class.human_attribute_name('control_objective_text'), control_objective_text]
    ]
  end

  private

    def set_proper_parent
      work_papers.each { |wp| wp.owner = self }
    end

    def prepare_work_paper work_paper
      work_paper.code_prefix =
        I18n.t 'code_prefixes.work_papers_in_control_objectives'
    end

    def check_for_final_review(_)
      raise 'Conclusion Final Review frozen' if review&.is_frozen?
    end

end
