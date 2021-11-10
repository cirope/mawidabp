module Findings::Reschedule
  extend ActiveSupport::Concern

  included do
    before_save :save_reschedule_count
  end

  def rescheduled?
    reschedule_count > 0
  end

  def calculate_reschedule_count
    count             = 0
    last_checked_date = last_being_implemented_follow_up_date

    follow_up_dates_to_check_against.each do |date|
      if last_checked_date && date < last_checked_date
        count            += 1
        last_checked_date = date
      end
    end

    count + (repeated_of&.calculate_reschedule_count || 0)
  end

  private

    def save_reschedule_count
      if unmark_rescheduled?
        self.reschedule_count = 0
      elsif calculate_reschedule_count?
        self.reschedule_count = calculate_reschedule_count
      end
    end

    def calculate_reschedule_count?
      recalculate_attributes_changed? &&
        repeated_or_on_final_review?  &&
        being_implemented?
    end

    def recalculate_attributes_changed?
      calculate_by_follow_up_date? || calculate_by_state?
    end

    def calculate_by_follow_up_date?
      follow_up_date_changed? && follow_up_date.present?
    end

    def calculate_by_state?
      state_changed? && follow_up_date.present?
    end

    def repeated_or_on_final_review?
      repeated_of&.follow_up_date.present? || final_review_created_at.present?
    end

    def last_being_implemented_follow_up_date
      if implemented? || implemented_audited?
        last_being_implemented = versions.reverse.detect do |v|
          prev = v.reify dup: true

          prev&.being_implemented? || prev&.awaiting?
          v.reify(dup: true)&.being_implemented?
        end&.reify dup: true

        [last_being_implemented&.follow_up_date, follow_up_date].compact.min
      else
        follow_up_date
      end
    end

    def follow_up_dates_to_check_against
      follow_up_dates = []

      follow_up_dates << follow_up_date_was if not_extension_was? && follow_up_date_was.present?
      follow_up_dates << follow_up_date if not_extension? && follow_up_date.present?

      follow_up_dates.compact.sort.reverse

      versions_after_final_review.reverse.each do |v|
        prev = v.reify dup: true
        date = prev.follow_up_date if (prev&.being_implemented? && prev&.not_extension?) || prev&.awaiting?

        follow_up_dates << date if date.present?
      end

      if repeated_of&.follow_up_date
        follow_up_dates << repeated_of.follow_up_date
      end

      follow_up_dates
    end

    def unmark_rescheduled?
      follow_up_date_changed?                        &&
        follow_up_date.present?                      &&
        final_review_created_at.blank?               &&
        !repeated_of&.rescheduled?                   &&
        repeated_of&.follow_up_date.present?         &&
        follow_up_date <= repeated_of.follow_up_date
    end
end
