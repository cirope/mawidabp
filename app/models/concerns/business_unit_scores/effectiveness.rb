module BusinessUnitScores::Effectiveness
  extend ActiveSupport::Concern

  def effectiveness
    highest_qualification = ControlObjectiveItem.qualifications_values.max

    if highest_qualification > 0 && scores.present?
      sum     = scores.sum { |s| s * 100.0 / highest_qualification }
      average = sum / scores.size
    end

    scores.empty? ? 100 : average.round
  end

  private

    def scores
      [
        design_score,
        compliance_score,
        sustantive_score
      ].compact
    end
end
