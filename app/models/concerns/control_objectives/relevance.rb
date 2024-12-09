module ControlObjectives::Relevance
  extend ActiveSupport::Concern

  def relevance_text
    if REVIEW_MANUAL_SCORE
      Current.organization.score_text_for(
        type:  'relevance_scores',
        date:  created_at,
        value: relevance
      )
    else
      relevance = self.class.relevances.detect { |r| r.last == self.relevance }

      relevance ? I18n.t("relevance_types.#{relevance.first}") : ''
    end
  end
end
