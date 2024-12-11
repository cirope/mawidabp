module ControlObjectiveItems::Relevance
  extend ActiveSupport::Concern

  def relevance_text show_value: false
    if REVIEW_MANUAL_SCORE
      Current.organization.relevance_text_for date: created_at, value: relevance
    else
      relevance = self.class.relevances.detect do |r|
        r.last == self.relevance
      end

      if relevance
        text = I18n.t "relevance_types.#{relevance.first}"

        show_value ? "#{text} (#{relevance.last})" : text
      end
    end
  end
end
