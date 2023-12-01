# frozen_string_literal: true

class Findings::RescheduleStrategies::GeneralStrategy < Findings::RescheduleStrategies::Strategy
  def initialize; end;

  def states_that_calculate_reschedule_count? finding
    finding.being_implemented?
  end

  def last_version_for_reschedule finding
    finding.versions.reverse.detect do |v|
      v.reify(dup: true)&.being_implemented?
    end&.reify dup: true
  end

  def follow_up_dates_to_check_against finding
    follow_up_dates = [
      finding.follow_up_date,
      finding.follow_up_date_was
    ].compact.sort.reverse

    finding.versions_after_final_review.reverse.each do |v|
      prev = v.reify dup: true

      if prev&.being_implemented? && prev&.follow_up_date
        follow_up_dates << prev.follow_up_date
      end
    end

    if finding.repeated_of&.follow_up_date
      original_finding = finding.original_finding

      original_finding.versions_before_final_review.reverse.each do |v|
        prev = v.reify dup: true

        if prev&.being_implemented? && prev&.follow_up_date
          follow_up_dates << prev.follow_up_date
        end
      end

      follow_up_dates << finding.repeated_of.follow_up_date
    end

    follow_up_dates
  end
end
