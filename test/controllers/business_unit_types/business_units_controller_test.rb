# frozen_string_literal: true

require 'test_helper'

class BusinessUnitTypes::BusinessUnitsControllerTest < ActionController::TestCase
  setup do
    login

    @business_unit = business_units :business_unit_one
  end

  test 'assert response get edit' do
    get :edit, params: {
      business_unit_type_id: @business_unit.business_unit_type.id,
      id: @business_unit.id
    }

    assert_response :success
  end

  test 'assert response update' do
    new_business_unit_type = business_unit_types :consolidated_substantive

    patch :update, params: {
      business_unit_type_id: @business_unit.business_unit_type.id,
      id: @business_unit.id,
      business_unit: {
        name: 'updated',
        business_unit_type_id: new_business_unit_type.id
      }
    }

    assert_response :redirect
    assert_equal I18n.t('business_unit.correctly_updated'), flash[:notice]
    assert_redirected_to business_unit_types_path

    @business_unit.reload

    assert_equal 'updated', @business_unit.name
    assert_equal new_business_unit_type.id, @business_unit.business_unit_type.id
  end
end
