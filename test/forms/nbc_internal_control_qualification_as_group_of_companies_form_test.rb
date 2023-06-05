# frozen_string_literal: true

require 'test_helper'

class NbcInternalControlQualificationAsGroupOfCompaniesFormTest < ActiveSupport::TestCase
  setup do
    set_organization

    @form = NbcInternalControlQualificationAsGroupOfCompaniesForm.new(
      OpenStruct.new(
        period_id: periods(:current_period).id,
        date: Date.today,
        cc: 'cc',
        name: 'name',
        objective: 'objective',
        conclusion: 'conclusion',
        introduction_and_scope: 'introduction and scope',
        previous_period_id: periods(:past_period).id
      )
    )
  end

  test 'previous_period_id should be present' do
    refute @form.validate({ previous_period_id: '' })
    assert_error @form, :previous_period_id, :blank
  end

  test 'previous_period must be before period' do
    refute @form.validate({ previous_period_id: periods(:unused_period).id })
    assert_error @form, :previous_period_id, :must_be_before_period

    refute @form.validate({ previous_period_id: periods(:current_period).id })
    assert_error @form, :previous_period_id, :must_be_before_period
  end

  test 'should attribute previous_period_id' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:previous_period_id),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.previous_period_id')
  end
end
