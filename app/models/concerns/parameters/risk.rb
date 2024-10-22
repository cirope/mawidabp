module Parameters::Risk
  extend ActiveSupport::Concern

  included do
    ::RISK_TYPES = risk_types unless defined? ::RISK_TYPES
  end

  DEFAULT_RISK_TYPES = {
    low:    0,
    medium: 1,
    high:   2
  }

  module ClassMethods
    def risks
      raise 'Risk configuration error' if valid_risk_types?

      RISK_TYPES
    end

    def risks_values
      RISK_TYPES.values
    end

    def highest_risks
      [RISK_TYPES[:high]]
    end

    private

      def risk_types
        finding_risk_types = ENV['FINDING_RISK_TYPES'] || '{}'

        if JSON.parse(finding_risk_types).present?
          JSON.parse(finding_risk_types).with_indifferent_access
        else
          DEFAULT_RISK_TYPES
        end
      end

      def valid_risk_types?
        risk_types      = RISK_TYPES.keys.map &:to_sym
        i18n_risk_types = I18n.translate('risk_types').keys

        (risk_types - i18n_risk_types).any?
      end
  end
end
