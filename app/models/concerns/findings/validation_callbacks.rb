module Findings::ValidationCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :set_proper_parent
    before_validation :change_review_code, on: :update
  end

  private

    def set_proper_parent
      finding_answers.each          { |fa|  fa.finding  = self }
      finding_relations.each        { |fr|  fr.finding  = self }
      finding_user_assignments.each { |fua| fua.finding = self }
      work_papers.each              { |wp|  wp.owner    = self }
    end

    def change_review_code
      if control_objective_changed?
        old = ControlObjectiveItem.find control_objective_item_id_was
        new = ControlObjectiveItem.find control_objective_item_id

        raise 'Can not change to a frozen review!' if new.review.try :is_frozen?

        switch_control_objective old, new unless old.review_id == new.review_id
      end
    end

    def control_objective_changed?
      control_objective_item_id_changed? &&
        control_objective_item_id &&
        ControlObjectiveItem.exists?(control_objective_item_id)
    end

    def switch_control_objective old, new
      self.control_objective_item = old
      self.review_code = next_code new.review

      # Para evitar que sea tenido en cuenta en la próxima iteración
      self.work_papers.each { |wp| wp.code = nil }
      self.work_papers.each { |wp| wp.code = last_work_paper_code(new.review).next }

      self.control_objective_item = new
    end
end
