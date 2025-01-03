module Parameters::Relevance
  extend ActiveSupport::Concern

  included do
    ::RELEVANCE_TYPES = relevance_types unless defined? ::RELEVANCE_TYPES
  end

  DEFAULT_RELEVANCE_TYPES = {
    not_rated:    0,
    low:          1,
    moderate_low: 2,
    moderate:     3,
    high:         4,
    critical:     5
  }

  def relevances
    self.class.relevances date:      created_at,
                          translate: true
  end

  module ClassMethods
    def relevances show_value: !USE_SHORT_RELEVANCE,
                   date:       nil,
                   translate:  false

      if REVIEW_MANUAL_SCORE && Current.organization
        Current.organization.relevance(date: date).with_indifferent_access
      elsif translate
        RELEVANCE_TYPES.map do |k, v|
          text = [
            I18n.t("relevance_types.#{k}"),
            ("(#{v})" if show_value)
          ].compact.join(' ')

          [text, v]
        end
      else
        RELEVANCE_TYPES
      end
    end

    def relevances_values date: nil
      relevances(date: date).values
    end

    private

      def relevance_types
        if USE_SHORT_RELEVANCE
          {
            no:  1,
            yes: 5
          }
        else
          DEFAULT_RELEVANCE_TYPES
        end
      end
  end

  def relevance_label
    type = RELEVANCE_TYPES.invert[relevance] if relevance

    I18n.t "relevance_types.#{type}" if type
  end
end
