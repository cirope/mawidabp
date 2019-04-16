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

  private

    def highest_qualification
      self.class.qualifications_values.max
    end
end
