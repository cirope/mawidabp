require 'test_helper'

class FindingsHelperTest < ActionView::TestCase
  test 'Should extension enabled when it never was being implementation' do
    finding = findings :incomplete_weakness

    assert extension_enabled?(finding)
  end

  test 'Should extension enabled when it is in the being implementation and has extension' do
    finding = findings :being_implemented_weakness

    finding.versions.each do |v|
      if v.object['state'] == Finding::STATUS[:being_implemented]
        v.object['extension'] = true
        v.save
      end
    end

    finding.extension = true

    assert extension_enabled?(finding)
  end

  test 'Should extension enabled when it is a new record' do
    finding = Finding.new

    assert extension_enabled?(finding)
  end

  test 'Should not extension enabled when have version in being implemented and extension in false' do
    finding = findings :being_implemented_weakness

    refute extension_enabled?(finding)
  end

  test 'Should first version in being implementation when is a new record' do
    finding = Finding.new

    assert first_version_in_being_implementation?(finding)
  end

  test 'Should first version in being implementation when it never was being implementation' do
    finding = findings :incomplete_weakness

    assert first_version_in_being_implementation?(finding)
  end

  test 'Should not first version in being implementation when have version in being implemented and extension in false' do
    finding = findings :being_implemented_weakness

    refute first_version_in_being_implementation?(finding)
  end

  test 'Data for submit' do
    skip unless USE_SCOPE_CYCLE

    finding       = findings :being_implemented_weakness
    expected_hash = {
                      data: {
                        confirm_message: I18n.t('findings.weakness.confirm_first_version_being_implemented_withou_extension',
                                                {
                                                  state: I18n.t('findings.state.being_implemented'),
                                                  extension: Finding.human_attribute_name(:extension)
                                                }),
                        checkbox_target: '#finding_extension',
                        target_value_checkbox: false,
                        state_target: Finding::STATUS[:being_implemented],
                        input_with_state: '#finding_state',
                        condition_to_receive_confirm: first_version_in_being_implementation?(finding) }
                    }

    assert_equal expected_hash, data_for_submit(finding)
  end

  test 'should return suggestion to add days follow up date depending on the risk' do
    assert_equal suggestion_to_add_days_follow_up_date_depending_on_the_risk, 
                 Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk.to_json
  end

  test 'should return states that suggest follow up date' do
    assert_equal states_that_suggest_follow_up_date, 
                 Finding.states_that_suggest_follow_up_date
  end

  test 'should return data options for suggested follow up date' do
    expected = {
      target_input_with_origination_date: '#weakness_origination_date',
      target_input_with_risk: '#weakness_risk',
      target_input_with_state: '#weakness_state',
      target_values_states_change_label: Finding.states_that_suggest_follow_up_date,
      days_to_add: Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk.to_json,
      suffix: I18n.t('findings.weakness.follow_up_date_label_append'),
      target_input_with_label: '#weakness_follow_up_date'
    }

    assert_equal data_options_for_suggested_follow_up_date, expected
  end
end
