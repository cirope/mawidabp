module WeaknessTemplates::Risk
  extend ActiveSupport::Concern

  def risk_text
    if REVIEW_MANUAL_SCORE
      Current.organization.score_text_for(
        type:  'risk_scores',
        date:  created_at,
        value: risk
      )
    else
      risk = self.class.risks.detect { |r| r.last == self.risk }

      risk ? I18n.t("risk_types.#{risk.first}") : ''
    end
  end
end
