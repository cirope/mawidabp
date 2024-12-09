module Weaknesses::Score
  extend ActiveSupport::Concern

  def take_as_new_for_score? date: Time.zone.today
    !take_as_repeated_for_score?(date: date) && !take_as_old_for_score?(date: date)
  end

  def take_as_repeated_for_score? date: Time.zone.today
    is_old = take_as_old_for_score? date: date

    if WEAKNESS_SCORE_OBSOLESCENCE == 0
      repeated_of
    elsif !is_old && repeated_of && repeated_of.origination_date
      expiration_date = date - WEAKNESS_SCORE_OBSOLESCENCE.months
      follow_up_date  = repeated_of.all_follow_up_dates.last ||
                        repeated_of.follow_up_date           ||
                        Time.zone.today
      is_obsolete     = repeated_of.origination_date < expiration_date
      has_expired     = follow_up_date < date

      is_obsolete || has_expired || repeated_of.rescheduled?
    end
  end

  def take_as_old_for_score? date: Time.zone.today
    check_obsolescence = WEAKNESS_SCORE_OBSOLESCENCE_START &&
                         WEAKNESS_SCORE_OBSOLESCENCE_START <= date

    check_obsolescence &&
      origination_date &&
      (origination_date < date - 2.years)
  end

  def risk_weight
    risk.next
  end

  def state_weight
    being_implemented? ? 1 : 0
  end

  def age_weight date: Time.zone.today
    w_origination_date = origination_date ? origination_date : date
    age_in_days        = (date - w_origination_date).days

    case
    when age_in_days <= 2.years
      1
    when age_in_days <= 4.years
      1.5
    when age_in_days <= 6.years
      2
    else
      2.5
    end
  end
end
