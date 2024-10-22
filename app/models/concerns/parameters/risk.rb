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
      raise 'Risk configuration error' unless valid_risk_types?

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
        finding_risk_types = JSON.parse ENV['FINDING_RISK_TYPES'] || '{}'

        if finding_risk_types.present?
          finding_risk_types.symbolize_keys
        else
          DEFAULT_RISK_TYPES
        end
      end

      def valid_risk_types?
        risk_types        = RISK_TYPES.keys
        risk_types_values = RISK_TYPES.values.tally.select { |_, count| count > 1 }.keys
        i18n_risk_types   = I18n.translate('risk_types').keys

        (risk_types - i18n_risk_types).blank? && risk_types_values.blank?
      end
  end
end
