module Parameters::Risk
  extend ActiveSupport::Concern

  included do
    ::RISK_TYPES = risk_types unless defined? ::RISK_TYPES
  end

  RISK_TYPES_DEFAULT = {
    low:    0,
    medium: 1,
    high:   2
  }

  module ClassMethods
    def risks
      raise 'Traslation error' if untranslated_risk_types?

      RISK_TYPES
    end

    def risks_values
      risks.values
    end

    def highest_risks
      [RISK_TYPES[:high]]
    end

    private

      def risk_types
        if ENV['FINDING_RISK_TYPES'].present? && JSON.parse(ENV['FINDING_RISK_TYPES']).present?
          JSON.parse(ENV['FINDING_RISK_TYPES']).transform_keys &:to_sym
        else
          RISK_TYPES_DEFAULT
        end
      end

      def untranslated_risk_types?
        types = JSON.parse ENV['FINDING_RISK_TYPES'] || {}

        risk_types      = types.keys.map &:to_sym
        i18n_risk_types = I18n.translate('risk_types').keys

        (risk_types - i18n_risk_types).any?
      end
  end
end
