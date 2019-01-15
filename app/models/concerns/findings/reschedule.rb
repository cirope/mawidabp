module Findings::Reschedule
  extend ActiveSupport::Concern

  included do
    before_save :mark_as_rescheduled_if_apply
  end

  def mark_as_rescheduled_if_apply
    self.rescheduled ||= just_rescheduled? || rescheduled_by_repetition?

    self.rescheduled = false if unmark_rescheduled?
  end

  def mark_as_rescheduled?
    was_rescheduled? || repeated_of&.mark_as_rescheduled?
  end

  private

    def just_rescheduled?
      follow_up_date_changed?               &&
        follow_up_date.present?             &&
        follow_up_date_was.present?         &&
        follow_up_date > follow_up_date_was &&
        final_review_created_at.present?
    end

    def rescheduled_by_repetition?
      repeated_of&.rescheduled || repeated_of_follow_up_date_changed?
    end

    def repeated_of_follow_up_date_changed?
      follow_up_date_changed?                       &&
        follow_up_date.present?                     &&
        repeated_of&.follow_up_date.present?        &&
        follow_up_date > repeated_of.follow_up_date
    end

    def was_rescheduled?
      was_rescheduled = follow_up_date && versions_after_final_review.any? do |v|
        date = v.reify(dup: true)&.follow_up_date

        date.present? && date < follow_up_date
      end

      was_rescheduled || rescheduled_on_repetition?
    end

    def rescheduled_on_repetition?
      follow_up_date.present?                       &&
        repeated_of&.follow_up_date.present?        &&
        follow_up_date > repeated_of.follow_up_date
    end

    def unmark_rescheduled?
      follow_up_date_changed?                        &&
        follow_up_date.present?                      &&
        final_review_created_at.blank?               &&
        !repeated_of&.rescheduled                    &&
        repeated_of&.follow_up_date.present?         &&
        follow_up_date <= repeated_of.follow_up_date
    end
end
