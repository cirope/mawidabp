module WeaknessTemplates::Risk
  extend ActiveSupport::Concern

  def risk_text
    risk = self.class.risks.detect { |r| r.last == self.risk }

    risk ? I18n.t("risk_types.#{risk.first}") : ''
  end
end
