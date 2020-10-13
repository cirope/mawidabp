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
    r = Review.list.find(review_id).previous

    if r.present?
      coi = r.control_objective_items.list.
        where(
          control_objective_id: control_objective_id
        ).where(
          'created_at = ?', created_at
        ).order(
          created_at: :desc
        ).first
    end

    coi
  end

  private

    def highest_qualification
      self.class.qualifications_values.max
    end
end
