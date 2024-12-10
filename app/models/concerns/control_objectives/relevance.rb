module ControlObjectives::Relevance
  extend ActiveSupport::Concern

  def relevance_text
    if REVIEW_MANUAL_SCORE
      Current.organization.relevance_text_for date: created_at, value: relevance
    else
      relevance = self.class.relevances.detect { |r| r.last == self.relevance }

      relevance ? I18n.t("relevance_types.#{relevance.first}") : ''
    end
  end
end
