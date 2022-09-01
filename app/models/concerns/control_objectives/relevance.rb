module ControlObjectives::Relevance
  extend ActiveSupport::Concern

  def relevance_text
    relevance = self.class.relevances.detect { |r| r.last == self.relevance }

    relevance ? I18n.t("relevance_types.#{relevance.first}") : ''
  end
end
