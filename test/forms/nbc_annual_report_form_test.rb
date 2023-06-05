# frozen_string_literal: true

require 'test_helper'

class NbcAnnualReportFormTest < ActiveSupport::TestCase
  setup do
    set_organization

    @form = NbcAnnualReportForm.new(OpenStruct.new(
                                      period_id: periods(:current_period).id,
                                      date: Date.today,
                                      cc: 'cc',
                                      name: 'name',
                                      objective: 'objective',
                                      conclusion: 'conclusion',
                                      introduction_and_scope: 'introduction and scope'
                                    ))
  end

  test 'should require all fields' do
    refute @form.validate(
      {
        period_id: '',
        date: '',
        cc: '',
        name: '',
        objective: '',
        conclusion: '',
        introduction_and_scope: ''
      }
    )

    assert_error @form, :period_id, :blank
    assert_error @form, :date, :blank
    assert_error @form, :cc, :blank
    assert_error @form, :name, :blank
    assert_error @form, :objective, :blank
    assert_error @form, :conclusion, :blank
    assert_error @form, :introduction_and_scope, :blank
  end

  test 'should set date' do
    @form.date = '12/01/2021'

    assert_equal @form.date, Date.parse('12/01/2021')
  end

  test 'should attribute period_id' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:period_id),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.period_id')
  end

  test 'should attribute date' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:date),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.date')
  end

  test 'should attribute cc' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:cc),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.cc')
  end

  test 'should attribute name' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:name),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.name')
  end

  test 'should attribute objective' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:objective),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.objective')
  end

  test 'should attribute conclusion' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:conclusion),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.conclusion')
  end

  test 'should attribute introduction and scope' do
    assert_equal NbcAnnualReportForm.human_attribute_name(:introduction_and_scope),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.introduction_and_scope')
  end
end
