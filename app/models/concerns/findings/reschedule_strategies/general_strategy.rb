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
    follow_up_dates = []

    finding.versions_after_final_review.each do |v|
      prev = v.reify dup: true

      if prev&.being_implemented? && prev&.follow_up_date && prev&.follow_up_date < finding.follow_up_date
        follow_up_dates << prev.follow_up_date
      end
    end

    if finding.repeated_of&.follow_up_date
      finding_ok = finding.final == true ? finding.repeated_of&.latest : finding

      finding_ok.versions_before_final_review.each do |v|
        prev = v.reify dup: true

        if prev&.being_implemented? && prev&.follow_up_date && prev&.follow_up_date < finding.follow_up_date
          follow_up_dates << prev.follow_up_date
        end
      end
    end

    follow_up_dates.uniq
  end
end
