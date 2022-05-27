# frozen_string_literal: true

require 'test_helper'

class Findings::RescheduleStrategies::PatStrategyTest < ActiveSupport::TestCase
  setup do
    skip unless USE_SCOPE_CYCLE
  end

  test 'should return true states that calculate reschedule count when is awaiting' do
    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:awaiting]
    strategy      = Findings::RescheduleStrategies::PatStrategy.new

    assert strategy.states_that_calculate_reschedule_count?(finding)
  end

  test 'should return true states that calculate reschedule count when is being implemented' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::PatStrategy.new

    assert strategy.states_that_calculate_reschedule_count?(finding)
  end

  test 'should return false states that calculate reschedule count when is not being implemented or awaiting' do
    finding  = findings :unconfirmed_for_notification_weakness
    strategy = Findings::RescheduleStrategies::PatStrategy.new

    refute strategy.states_that_calculate_reschedule_count?(finding)
  end

  test 'should return nil last version for reschedule when dont have version with being_implemented or awaiting and dont have extension' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::PatStrategy.new

    version_awaiting_without_extension =
      versions :finding_being_implemented_weakness_without_extension_and_awaiting_after_final_review
    version_being_implemented_without_extension =
      versions :finding_being_implemented_weakness_without_extension_after_final_review

    version_awaiting_without_extension.destroy!
    version_being_implemented_without_extension.destroy!

    assert_nil strategy.last_version_for_reschedule(finding)
  end

  test 'should return last version being implemented or awaiting without extension in last version for reschedule' do
    finding  = findings :being_implemented_weakness
    strategy = Findings::RescheduleStrategies::PatStrategy.new

    last_version =
      finding.versions.reverse.detect do |v|
        prev = v.reify dup: true

        Finding.states_that_allow_extension.include?(prev&.state) && !prev&.extension
      end&.reify dup: true

    assert_equal last_version, strategy.last_version_for_reschedule(finding)
  end

  test 'should return follow up dates to check against' do
    finding                = findings :being_implemented_weakness
    strategy               = Findings::RescheduleStrategies::PatStrategy.new
    finding.follow_up_date = finding.follow_up_date + 1.days
    finding.repeated_of    = findings :being_implemented_weakness_on_final

    expected               = [
      finding.follow_up_date,
      finding.follow_up_date_was
    ].compact.sort.reverse

    finding.versions_after_final_review.reverse.each do |v|
      prev = v.reify dup: true

      if Finding.states_that_allow_extension.include?(prev&.state) && !prev&.extension
        expected << prev.follow_up_date
      end
    end

    expected << finding.repeated_of.follow_up_date

    assert_equal expected, strategy.follow_up_dates_to_check_against(finding)
  end
end
