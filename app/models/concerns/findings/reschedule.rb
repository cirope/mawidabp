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
    last_checked_date = last_follow_up_date_for_reschedule

    reschedule_strategy.follow_up_dates_to_check_against(self).each do |date|
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
        reschedule_strategy.states_that_calculate_reschedule_count?(self)
    end

    def recalculate_attributes_changed?
      calculate_by_follow_up_date? || calculate_by_state? || calculate_by_repeated_of?
    end

    def calculate_by_follow_up_date?
      follow_up_date_changed? && follow_up_date.present?
    end

    def calculate_by_state?
      state_changed? && follow_up_date.present?
    end

    def calculate_by_repeated_of?
      repeated_of_id_changed? && follow_up_date.present?
    end

    def repeated_or_on_final_review?
      repeated_of&.follow_up_date.present? || final_review_created_at.present?
    end

    def last_follow_up_date_for_reschedule
      if implemented? || implemented_audited?
        [
          reschedule_strategy.last_version_for_reschedule(self)&.follow_up_date,
          follow_up_date
        ].compact.min
      else
        follow_up_date
      end
    end

    def unmark_rescheduled?
      follow_up_date_changed?                        &&
        follow_up_date.present?                      &&
        final_review_created_at.blank?               &&
        !repeated_of&.rescheduled?                   &&
        repeated_of&.follow_up_date.present?         &&
        follow_up_date <= repeated_of.follow_up_date
    end

    def reschedule_strategy
      @reschedule_strategy ||= if USE_SCOPE_CYCLE
                                 Findings::RescheduleStrategies::PatStrategy.new
                               else
                                 Findings::RescheduleStrategies::GeneralStrategy.new
                               end
    end
end
