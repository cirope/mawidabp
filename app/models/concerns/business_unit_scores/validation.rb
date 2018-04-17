module BusinessUnitScores::Validation
  extend ActiveSupport::Concern

  included do
    validates :business_unit_id, presence: true, uniqueness: { scope: :control_objective_item_id }
    validate :score_completion
  end

  private

    def score_completion
      if design_score.blank? && compliance_score.blank? && sustantive_score.blank?
        errors.add :design_score,     :blank
        errors.add :compliance_score, :blank
        errors.add :sustantive_score, :blank
      end
    end
end
