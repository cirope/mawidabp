module Parameters::Relevance
  extend ActiveSupport::Concern

  RELEVANCE_TYPES = {
    not_rated: 0,
    low: 1,
    moderate_low: 2,
    moderate: 3,
    high: 4,
    critical: 5
  }

  module ClassMethods
    def relevances
      RELEVANCE_TYPES
    end

    def relevances_values
      RELEVANCE_TYPES.values
    end
  end

  def relevance_label
    I18n.t "relevance_types.#{RELEVANCE_TYPES.invert[relevance]}" if relevance
  end
end
