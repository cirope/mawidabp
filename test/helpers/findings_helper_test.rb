require 'test_helper'

class FindingsHelperTest < ActionView::TestCase
  test 'Should extension enabled when dont have final review' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :incomplete_weakness

    assert extension_enabled?(finding)
  end

  test 'Should extension not enabled when have final and dont have extension' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    refute extension_enabled?(finding)
  end

  test 'Should extension enabled when have final review and have extension' do
    skip unless USE_SCOPE_CYCLE

    finding           = findings :being_implemented_weakness
    finding.extension = true

    assert extension_enabled?(finding)
  end

  test 'Data for submit when finding have extension and final review' do
    finding           = findings :being_implemented_weakness
    finding.extension = true

    expected_hash = if USE_SCOPE_CYCLE
                      {
                        data: {
                          confirm_message: I18n.t('findings.form.confirm_finding_without_extension',
                                                  {
                                                    extension: Finding.human_attribute_name(:extension)
                                                  }),
                          checkbox_target: '#finding_extension',
                          target_value_checkbox: false,
                          states_target: Finding.states_that_allow_extension,
                          input_with_state: '#finding_state',
                          condition_to_receive_confirm: finding.review.conclusion_final_review.present? && finding.extension
                        }
                      }
                    else
                      {}
                    end

    assert_equal expected_hash, data_for_submit(finding)
  end

  test 'Data for submit when finding have final review but dont have extension' do
    finding = findings :being_implemented_weakness

    expected_hash = if USE_SCOPE_CYCLE
                      {
                        data: {
                          confirm_message: I18n.t('findings.form.confirm_finding_without_extension',
                                                  {
                                                    extension: Finding.human_attribute_name(:extension)
                                                  }),
                          checkbox_target: '#finding_extension',
                          target_value_checkbox: false,
                          states_target: Finding.states_that_allow_extension,
                          input_with_state: '#finding_state',
                          condition_to_receive_confirm: finding.review.conclusion_final_review.present? && finding.extension
                        }
                      }
                    else
                      {}
                    end

    assert_equal expected_hash, data_for_submit(finding)
  end

  test 'Data for submit when finding dont have final review' do
    finding = findings :incomplete_weakness

    expected_hash = if USE_SCOPE_CYCLE
                      {
                        data: {
                          confirm_message: I18n.t('findings.form.confirm_finding_without_extension',
                                                  {
                                                    extension: Finding.human_attribute_name(:extension)
                                                  }),
                          checkbox_target: '#finding_extension',
                          target_value_checkbox: false,
                          states_target: Finding.states_that_allow_extension,
                          input_with_state: '#finding_state',
                          condition_to_receive_confirm: finding.review.conclusion_final_review.present? && finding.extension
                        }
                      }
                    else
                      {}
                    end

    assert_equal expected_hash, data_for_submit(finding)
  end

  test 'should return data options for suggested follow up date' do
    type_form = 'finding'

    expected = if USE_SCOPE_CYCLE
                 {
                   target_input_with_origination_date: "##{type_form}_origination_date",
                   target_input_with_risk: "##{type_form}_risk",
                   target_input_with_state: "##{type_form}_state",
                   target_values_states_change_label: Finding.states_that_suggest_follow_up_date,
                   days_to_add: Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk.to_json,
                   suffix: I18n.t('findings.form.follow_up_date_label_append'),
                   target_input_with_label: "##{type_form}_follow_up_date"
                 }
               else
                 {}
               end

    assert_equal data_options_for_suggested_follow_up_date(type_form), expected
  end
end
