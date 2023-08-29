# frozen_string_literal: true

class Findings::RescheduleStrategies::Strategy
  def initialize finding
    raise 'Cannot initialize an abstract Strategies For Reschedule class'
  end

  def states_that_calculate_reschedule_count? finding
    raise NotImplementedError
  end

  def last_version_for_reschedule finding
    raise NotImplementedError
  end

  def follow_up_dates_to_check_against finding
    raise NotImplementedError
  end
end
