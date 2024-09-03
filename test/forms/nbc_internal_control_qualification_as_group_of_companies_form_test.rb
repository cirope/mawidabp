# frozen_string_literal: true

require 'test_helper'

class NbcInternalControlQualificationAsGroupOfCompaniesFormTest < ActiveSupport::TestCase
  setup do
    skip unless Current.conclusion_pdf_format == 'nbc'

    set_organization

    other_organization = organizations(:google)

    BusinessUnitType.create([
      { name: "Cycle", business_unit_label: 'C', organization: other_organization },
      { name: "Consolidated Substantive", business_unit_label: 'CS', organization: other_organization }
    ])

    business_unit_types = [
      business_unit_types(:bcra).name,
      business_unit_types(:consolidated_substantive).name,
      business_unit_types(:cycle).name
    ]

    @form = NbcInternalControlQualificationAsGroupOfCompaniesForm.new(
      OpenStruct.new(
        period_id: periods(:current_period).id,
        date: Date.today,
        cc: 'cc',
        name: 'name',
        objective: 'objective',
        conclusion: 'conclusion',
        introduction_and_scope: 'introduction and scope',
        previous_period_id: periods(:past_period).id,
        business_unit_types: business_unit_types
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

  test 'previous_period_id must have the same name' do
    refute @form.validate({ previous_period_id: periods(:third_period).id })
    assert_error @form, :previous_period_id, :must_have_the_same_name,
      organizations: [organizations(:google).name].to_sentence
  end

  test 'period_id must have the same name' do
    refute @form.validate({ period_id: periods(:third_period).id })
    assert_error @form, :period_id, :must_have_the_same_name,
      organizations: [organizations(:google).name].to_sentence
  end

  test 'business_unit_types must have the same name' do
    business_unit_types = [
      business_unit_types(:bcra).name,
      business_unit_types(:consolidated_substantive).name
    ]
    different_names     = [business_unit_types(:cycle).name]

    refute @form.validate({ business_unit_types: business_unit_types })
    assert_error @form, :business_unit_types, :must_have_the_same_business_unit_type_names,
      different_names: different_names.to_sentence, count: different_names.count
  end

  test 'should attribute previous_period_id' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:previous_period_id),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.previous_period_id')
  end

  test 'should attribute business_unit_types' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:business_unit_types),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.business_unit_types')
  end

  test 'should attribute organizations' do
    assert_equal NbcInternalControlQualificationAsGroupOfCompaniesForm.human_attribute_name(:organizations),
                 I18n.t('activemodel.attributes.nbc_annual_report_form.organizations')
  end
end
