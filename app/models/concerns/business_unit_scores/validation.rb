module BusinessUnitScores::Validation
  extend ActiveSupport::Concern

  included do
    validates :business_unit_id, presence: true
    validate :score_completion
  end

  private

    def score_completion
      if !design_score && !compliance_score && !sustantive_score
        errors.add :design_score,     :blank
        errors.add :compliance_score, :blank
        errors.add :sustantive_score, :blank
      end
    end
end
