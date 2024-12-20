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

  def priorities
    self.class.priorities date:      created_at,
                          translate: true
  end

  module ClassMethods
    def priorities date:      nil,
                   translate: false

      if REVIEW_MANUAL_SCORE && Current.organization
        Current.organization.priorities(date: date).with_indifferent_access
      elsif translate
        if SHOW_CONDENSED_PRIORITIES
          PRIORITY_TYPES.map do |k, v|
            [I18n.t("priority_types.#{k}"), v]
          end
        else
          PRIORITY_TYPES.map do |k, v|
            [[I18n.t("priority_types.#{k}"), "(#{v})"].join(' '), v]
          end
        end
      else
        PRIORITY_TYPES
      end
    end

    def priorities_values date: nil
      priorities(date: date).values
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
