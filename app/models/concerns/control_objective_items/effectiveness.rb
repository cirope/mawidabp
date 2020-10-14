module ControlObjectiveItems::Effectiveness
  extend ActiveSupport::Concern

  def effectiveness
    return 0 if exclude_from_score

    scores = [design_score, compliance_score, sustantive_score].compact

    if highest_qualification > 0 && scores.size > 0
      sum     = scores.sum { |s| s * 100.0 / highest_qualification }
      average = sum / scores.size
    end

    scores.empty? ? 100 : average.round
  end

  def previous_effectiveness
    previous_review = self.review.previous

    if previous_review.present?
      coi = previous_review.control_objective_items.
        where(
          control_objective_id: control_objective_id
        ).where(
          'created_at < ?', created_at
        ).order(
          created_at: :desc
        ).first

      coi&.effectiveness
    end
  end

  private

    def highest_qualification
      self.class.qualifications_values.max
    end
end
