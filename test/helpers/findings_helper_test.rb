require 'test_helper'

class FindingsHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

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
                                                  extension: Finding.human_attribute_name(:extension)),
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
                                                  extension: Finding.human_attribute_name(:extension)),
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
                                                  extension: Finding.human_attribute_name(:extension)),
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

  test 'should return next task expiration when it is not yet due' do
    finding = findings :being_implemented_weakness

    assert_equal next_task_expiration(finding),
                 content_tag(:span, " / #{l finding.next_task_expiration, format: :short}", class: 'text-success')
  end

  test 'should return next task expiration when it is due' do
    finding = findings :being_implemented_weakness
    task    = tasks :setup_all_things

    task.update! due_on: Time.zone.yesterday

    assert_equal next_task_expiration(finding),
                 content_tag(:span, " / #{l finding.next_task_expiration, format: :short}", class: 'strike bg-danger')
  end

  test 'should not return next task expiration' do
    finding = findings :being_implemented_weakness
    task    = tasks :setup_all_things

    task.update! status: Task.statuses['finished']

    assert_equal next_task_expiration(finding), ''
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
