module ConclusionReviews::Risks
  extend ActiveSupport::Concern

  def risk_text value: risk
    Current.organization.risks_text_for(
      date: created_at, value: value
    )
  end

  def planned_risk
    if risk = review.plan_item.risk_assessment_item&.risk
      risk_text(value: risk) || I18n.t('conclusion_reviews.risks.unknown')
    else
      I18n.t 'conclusion_reviews.risks.none'
    end
  end
end
