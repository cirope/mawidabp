require 'test_helper'

class FindingsHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

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
    expected = if USE_SCOPE_CYCLE
                 {
                   target_input_with_origination_date: '#weakness_origination_date',
                   target_input_with_risk: '#weakness_risk',
                   target_input_with_state: '#weakness_state',
                   target_values_states_change_label: Finding.states_that_suggest_follow_up_date,
                   days_to_add: Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk.to_json,
                   suffix: I18n.t('findings.weakness.follow_up_date_label_append'),
                   target_input_with_label: '#weakness_follow_up_date'
                 }
               else
                 {}
               end

    assert_equal data_options_for_suggested_follow_up_date, expected
  end

  test 'should return nil link to edit finding when user is can act as audited and exclude in finding' do
    finding                 = findings :being_implemented_weakness
    auth_user               = users :audited
    finding_user_assignment = finding_user_assignments :being_implemented_weakness_audited

    finding_user_assignment.destroy

    assert_nil link_to_edit_finding(finding, auth_user)
  end

  test 'should return nil link to edit finding when user is included in finding and finding is repeated' do
    auth_user     = users :audited
    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:repeated]

    finding.save!

    assert_nil link_to_edit_finding(finding, auth_user)
  end

  test 'should return nil link to edit finding when user is not can act as audited and finding is repeated' do
    auth_user     = users :supervisor
    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:repeated]

    finding.save!

    finding_user_assignment = finding_user_assignments :being_implemented_weakness_supervisor

    finding_user_assignment.destroy

    assert_nil link_to_edit_finding(finding, auth_user)
  end

  test 'should return link to edit finding when user is included in finding and finding is pending' do
    auth_user = users :audited
    finding   = findings :being_implemented_weakness

    assert_equal link_to_edit(edit_finding_path('incomplete', finding, user_id: params[:user_id])),
                 link_to_edit_finding(finding, auth_user)
  end

  test 'should return link to edit finding when user is not can act as audited and finding is pending' do
    auth_user               = users :supervisor
    finding                 = findings :being_implemented_weakness
    finding_user_assignment = finding_user_assignments :being_implemented_weakness_supervisor

    finding_user_assignment.destroy

    assert_equal link_to_edit(edit_finding_path('incomplete', finding, user_id: params[:user_id])),
                 link_to_edit_finding(finding, auth_user)
  end

  test 'should return nil link to edit finding when user is included in finding and current pdf format is not bic' do
    skip_if_bic_include_in_current_pdf_format

    auth_user             = users :audited
    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    assert_nil link_to_edit_finding(finding, auth_user)
  end

  test 'should return nil link to edit finding when user is not can act as audited and current pdf format is not bic' do
    skip_if_bic_include_in_current_pdf_format

    auth_user             = users :supervisor
    Current.user          = auth_user
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    finding_user_assignment = finding_user_assignments :being_implemented_weakness_supervisor

    finding_user_assignment.destroy

    assert_nil link_to_edit_finding(finding, auth_user)
  end

  test 'should return link to edit finding when user is included in finding and finding have final state' do
    skip_if_bic_exclude_in_current_pdf_format

    auth_user             = users :audited
    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    assert_equal link_to_edit(edit_bic_sigen_fields_finding_path('complete', finding)),
                 link_to_edit_finding(finding, auth_user)
  end

  test 'should return link to edit finding when user is not can act as audited and finding have final state' do
    skip_if_bic_exclude_in_current_pdf_format

    auth_user             = users :supervisor
    Current.user          = auth_user
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    finding_user_assignment = finding_user_assignments :being_implemented_weakness_supervisor

    finding_user_assignment.destroy

    assert_equal link_to_edit(edit_bic_sigen_fields_finding_path('complete', finding)),
                 link_to_edit_finding(finding, auth_user)
  end

  private

    def link_to_edit(*args)
      link_with_icon({ action: 'edit', icon: 'pen' }, *args)
    end

    def link_with_icon(options = {}, *args)
      arg_options = args.extract_options!

      arg_options.reverse_merge!(
        title: t("navigation.#{options.fetch(:action)}"),
        class: 'icon'
      )

      link_to *args, arg_options do
        icon 'fas', options.fetch(:icon)
      end
    end

    def skip_if_bic_include_in_current_pdf_format
      set_organization

      skip if %w(bic).include?(Current.conclusion_pdf_format)
    end

    def skip_if_bic_exclude_in_current_pdf_format
      set_organization

      skip if %w(bic).exclude?(Current.conclusion_pdf_format)
    end
end
