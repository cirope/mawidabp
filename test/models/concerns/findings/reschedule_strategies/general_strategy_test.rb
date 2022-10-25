# frozen_string_literal: true

require 'test_helper'

class Findings::RescheduleStrategies::GeneralStrategyTest < ActiveSupport::TestCase
  setup do
    skip if USE_SCOPE_CYCLE
  end

  test 'should return false states that calculate reschedule count when is awaiting' do
    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:awaiting]
    strategy      = Findings::RescheduleStrategies::GeneralStrategy.new

    refute strategy.states_that_calculate_reschedule_count?(finding)
  end

  test 'should return true states that calculate reschedule count when is being implemented' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::GeneralStrategy.new

    assert strategy.states_that_calculate_reschedule_count?(finding)
  end

  test 'should return nil last version for reschedule when dont have version with being_implemented' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::GeneralStrategy.new

    version_1_with_being_implemented =
      versions :finding_being_implemented_weakness_with_extension_before_final_review
    version_2_with_being_implemented =
      versions :first_finding_being_implemented_weakness_with_extension_after_final_review
    version_3_with_being_implemented =
      versions :second_finding_being_implemented_weakness_with_extension_after_final_review
    version_4_with_being_implemented =
      versions :finding_being_implemented_without_follow_update_weakness_without_extension_after_final_review
    version_5_with_being_implemented =
      versions :finding_being_implemented_weakness_without_extension_after_final_review

    version_1_with_being_implemented.destroy!
    version_2_with_being_implemented.destroy!
    version_3_with_being_implemented.destroy!
    version_4_with_being_implemented.destroy!
    version_5_with_being_implemented.destroy!

    assert_nil strategy.last_version_for_reschedule(finding)
  end

  test 'should return last version being implemented in last version for reschedule' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::GeneralStrategy.new

    last_version =
      finding.versions.reverse.detect do |v|
        v.reify(dup: true)&.being_implemented?
      end&.reify dup: true

    assert_equal last_version, strategy.last_version_for_reschedule(finding)
  end

  test 'should return follow up dates to check against' do
    finding                = findings :being_implemented_weakness
    strategy               = Findings::RescheduleStrategies::GeneralStrategy.new
    finding.follow_up_date = finding.follow_up_date + 1.days
    finding.repeated_of    = findings :being_implemented_weakness_on_final

    expected               = [
      finding.follow_up_date,
      finding.follow_up_date_was
    ].compact.sort.reverse

    finding.versions_after_final_review.reverse.each do |v|
      prev = v.reify dup: true

      if prev&.being_implemented? && prev&.follow_up_date
        expected << prev.follow_up_date
      end
    end

    expected << finding.repeated_of.follow_up_date

    assert_equal expected, strategy.follow_up_dates_to_check_against(finding)
  end
end
