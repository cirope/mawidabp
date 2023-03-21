# frozen_string_literal: true

require 'test_helper'

class NbcInternalControlQualificationAsGroupOfCompaniesFormTest < ActiveSupport::TestCase
  setup do
    @form = NbcInternalControlQualificationAsGroupOfCompaniesForm.new(
      OpenStruct.new(
        period_id: periods(:current_period).id,
        date: Date.today,
        cc: 'cc',
        name: 'name',
        objective: 'objective',
        conclusion: 'conclusion',
        introduction_and_scope: 'introduction and scope',
        business_unit_type_id: business_unit_types(:cycle).id,
        previous_period_id: periods(:past_period).id
      )
    )
  end

  test 'should require business unit type id' do
    @form.validate({ business_unit_type_id: '' })

    refute @form.valid?

    assert_error @form, :business_unit_type_id, :blank
  end

  test 'should require previous period id' do
    @form.validate({ previous_period_id: '' })

    refute @form.valid?

    assert_error @form, :previous_period_id, :blank
  end

  test 'should invalid because same period and previous period' do
    @form.validate({ previous_period_id: periods(:current_period).id })

    refute @form.valid?

    assert_error @form, :period_id, :must_be_different
    assert_error @form, :previous_period_id, :must_be_different
  end

  test 'should attribute business_unit_type_id' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:business_unit_type_id),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.business_unit_type_id')
  end

  test 'should attribute previous_period_id' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:previous_period_id),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.previous_period_id')
  end

  test 'should return business unit type' do
    assert_equal @form.business_unit_type, business_unit_types(:cycle)
  end

  test 'should return previous period' do
    assert_equal @form.previous_period, periods(:past_period)
  end
end
