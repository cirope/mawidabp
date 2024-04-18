module Settings::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :value, :organization, presence: true
    validates :name, :value, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :organization }
    validates :value,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 },
      if: :is_number?
    validate :validate_finding_stale_confirmed_days, if: -> { name == 'finding_stale_confirmed_days' }, on: :update
    validate :validate_finding_warning_expire_days, if: -> { name == 'finding_warning_expire_days' }
    validate :validate_finding_days_for_next_notifications, if: -> { name == 'finding_days_for_next_notifications' }, on: :update
  end

  private

    def is_number?
      DEFAULT_SETTINGS[name][:validates] == 'numericality' if DEFAULT_SETTINGS[name]
    end

    def validate_finding_stale_confirmed_days
      stale_day                 = value.to_i
      notification_days_setting = organization.settings.find_by(name: 'finding_days_for_next_notifications')
      notification_days_array   = notification_days_setting&.value.split(',').map(&:to_i)
      last_notification_day     = notification_days_array.max

      if stale_day <= last_notification_day
        errors.add(
          :value,
          :array_values_below, last_notification_day: last_notification_day, setting_description: notification_days_setting.description
        )
      end
    end

    def validate_finding_warning_expire_days
      expire_days_array = value.split(',').map(&:strip)

      add_errors_for_invalid_numbers expire_days_array, :value
      add_errors_for_duplicates expire_days_array, :value

      errors.add(:value, :empty) if expire_days_array.empty?
    end

    def validate_finding_days_for_next_notifications
      notification_days_array = value.split(',').map(&:strip)
      stale_day_setting       = organization.settings.find_by(name: 'finding_stale_confirmed_days')
      stale_day               = stale_day_setting&.value.to_i

      add_errors_for_invalid_numbers notification_days_array, :value
      add_errors_for_duplicates notification_days_array, :value

      errors.add(:value, :empty) if notification_days_array.empty?

      days_above = notification_days_array.select { |day| day.to_i >= stale_day }

      if days_above.any?
        errors.add(
          :value,
          :array_values_above, days_above: days_above.join(', '), stale_day: stale_day, setting_description: stale_day_setting.description
        )
      end
    end

    def add_errors_for_invalid_numbers array, attribute
      invalid_items = validate_numericality array

      errors.add(attribute, :invalid, invalid_days: invalid_items.join(', ')) if invalid_items.any?
    end

    def add_errors_for_duplicates array, attribute
      duplicate_items = check_duplicates array

      errors.add(attribute, :duplicate_array_values, duplicate_days: duplicate_items.join(', ')) if duplicate_items.any?
    end

    def validate_numericality array
      array.select { |item| !item.match?(/^\d+$/) }
    end

    def check_duplicates(array)
      array.select { |item| array.count(item) > 1 }.uniq
    end
end
