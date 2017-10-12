module Weaknesses::Risk
  extend ActiveSupport::Concern

  included do
    before_save :assign_highest_risk
  end

  def risk_text
    risk = self.class.risks.detect { |r| r.last == self.risk }

    risk ? I18n.t("risk_types.#{risk.first}") : ''
  end

  private

    def assign_highest_risk
      self.highest_risk = self.class.risks_values.max
    end
end
