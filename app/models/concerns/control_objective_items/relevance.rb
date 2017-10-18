module ControlObjectiveItems::Relevance
  extend ActiveSupport::Concern

  def relevance_text show_value: false
    relevance = self.class.relevances.detect do |r|
      r.last == self.relevance
    end

    if relevance
      text = I18n.t "relevance_types.#{relevance.first}"

      show_value ? "#{text} (#{relevance.last})" : text
    end
  end
end
