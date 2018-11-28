module Findings::Reschedule
  extend ActiveSupport::Concern

  included do
    before_save :mark_as_rescheduled_if_applies
  end

  def mark_as_rescheduled_if_applies
    self.rescheduled ||= follow_up_date_changed? &&
      follow_up_date_was.present? &&
      final_review_created_at.present?
  end

  def mark_as_rescheduled?
    was_rescheduled? || repeated_of&.mark_as_rescheduled?
  end

  private

    def was_rescheduled?
      versions_after_final_review.any? do |v|
        date = v.reify(dup: true)&.follow_up_date

        date.present? && date != follow_up_date
      end
    end
end
