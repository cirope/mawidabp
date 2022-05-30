module Parameters::Relevance
  extend ActiveSupport::Concern

  included do
    ::RELEVANCE_TYPES = relevance_types unless defined? ::RELEVANCE_TYPES
  end

  module ClassMethods
    def relevances
      RELEVANCE_TYPES
    end

    def relevances_values
      RELEVANCE_TYPES.values
    end

    private

      def relevance_types
        if USE_SHORT_RELEVANCE
          {
            no:  1,
            yes: 5
          }
        else
          {
            low:          1,
            moderate:     2,
            high:         3,
          }
        end
      end
  end

  def relevance_label
    type = RELEVANCE_TYPES.invert[relevance] if relevance

    I18n.t "relevance_types.#{type}" if type
  end
end
