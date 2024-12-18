module ConclusionReviews::Risks
  extend ActiveSupport::Concern

  def risk_text
    Current.organization.risks_text_for(
      date: created_at, value: risk
    )
  end
end
