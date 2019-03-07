module Weaknesses::Repeated
  extend ActiveSupport::Concern

  def take_as_repeated_for_score? date: Time.zone.today
    if WEAKNESS_SCORE_OBSOLESCENCE == 0
      repeated_of
    elsif repeated_of && repeated_of.origination_date
      expiration_date = date - WEAKNESS_SCORE_OBSOLESCENCE.months
      follow_up_date  = repeated_of.all_follow_up_dates.last ||
                        repeated_of.follow_up_date           ||
                        Time.zone.today
      is_obsolete     = repeated_of.origination_date < expiration_date
      has_expired     = follow_up_date < date

      is_obsolete || has_expired || repeated_of.rescheduled
    end
  end
end
