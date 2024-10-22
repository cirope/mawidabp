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
        risk_types = JSON.parse ENV['RISK_TYPES'] || '{}'

        raise 'Risk configuration error' unless valid_risk_types? risk_types

        if risk_types.present?
          risk_types.symbolize_keys
        else
          DEFAULT_RISK_TYPES
        end
      end

      def valid_risk_types? risk_types
        risk_types_keys    = risk_types.symbolize_keys.keys
        risk_values_unique = risk_types.values.uniq.size == risk_types.values.size
        i18n_risk_types    = I18n.translate('risk_types').keys

        (risk_types_keys - i18n_risk_types).blank? && risk_values_unique
      end
  end
end
