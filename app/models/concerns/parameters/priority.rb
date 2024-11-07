module Parameters::Priority
  extend ActiveSupport::Concern

  included do
    ::PRIORITY_TYPES = priority_types unless defined? ::PRIORITY_TYPES
  end

  DEFAULT_PRIORITY_TYPES = {
    low:    0,
    medium: 1,
    high:   2
  }

  module ClassMethods
    def priorities
      PRIORITY_TYPES
    end

    def priorities_values
      PRIORITY_TYPES.values
    end

    private

      def priority_types
        priority_types = JSON.parse ENV['PRIORITY_TYPES'] || '{}'

        raise 'Priority configuration error' unless valid_priority_types? priority_types

        if priority_types.present?
          priority_types.symbolize_keys
        else
          DEFAULT_PRIORITY_TYPES
        end
      end

      def valid_priority_types? priority_types
        priority_types_keys    = priority_types.symbolize_keys.keys
        unique_priority_values = priority_types.values.uniq.size == priority_types.values.size
        i18n_priority_types    = I18n.translate('priority_types').keys

        (priority_types_keys - i18n_priority_types).blank? && unique_priority_values
      end
    end
end
