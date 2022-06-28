# frozen_string_literal: true

class Findings::RescheduleStrategies::PatStrategy < Findings::RescheduleStrategies::Strategy
  def initialize; end;

  def states_that_calculate_reschedule_count? finding
    Finding.states_that_allow_extension.include?(finding.state) &&
      !finding.extension
  end

  def last_version_for_reschedule finding
    finding.versions.reverse.detect do |v|
      prev = v.reify dup: true

      Finding.states_that_allow_extension.include?(prev&.state) && !prev&.extension
    end&.reify dup: true
  end

  def follow_up_dates_to_check_against finding
    follow_up_dates = []

    follow_up_dates << finding.follow_up_date unless finding.extension
    follow_up_dates << finding.follow_up_date_was unless finding.extension_was

    follow_up_dates = follow_up_dates.compact.sort.reverse

    finding.versions_after_final_review.reverse.each do |v|
      prev = v.reify dup: true

      if Finding.states_that_allow_extension.include?(prev&.state) && !prev&.extension && prev&.follow_up_date
        follow_up_dates << prev.follow_up_date
      end
    end

    if finding.repeated_of&.follow_up_date
      follow_up_dates << finding.repeated_of.follow_up_date
    end

    follow_up_dates
  end
end
