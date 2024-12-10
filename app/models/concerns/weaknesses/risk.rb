module Weaknesses::Risk
  extend ActiveSupport::Concern

  included do
    before_save :assign_highest_risk
  end

  def risk_text
    if REVIEW_MANUAL_SCORE
      Current.organization.risks_text_for date: created_at, value: risk
    else
      risk = self.class.risks.detect { |r| r.last == self.risk }

      risk ? I18n.t("risk_types.#{risk.first}") : ''
    end
  end

  private

    def assign_highest_risk
      self.highest_risk = self.class.risks_values.max
    end
end
