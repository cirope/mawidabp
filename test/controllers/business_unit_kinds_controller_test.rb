require 'test_helper'

class BusinessUnitKindsControllerTest < ActionController::TestCase

  setup do
    @business_unit_kind = business_unit_kinds :central

    login
  end

  test 'should get index' do
    get :index

    assert_response :success
  end

  test 'should get new' do
    get :new

    assert_response :success
  end

  test 'should create business_unit_kind' do
    assert_difference 'BusinessUnitKind.count' do
      post :create, params: {
        business_unit_kind: {
          name: 'Regional'
        }
      }
    end

    assert_redirected_to business_unit_kind_url(BusinessUnitKind.last)
  end

  test 'should show business_unit_kind' do
    get :show, params: { id: @business_unit_kind }

    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @business_unit_kind }

    assert_response :success
  end

  test 'should update business_unit_kind' do
    patch :update, params: {
      id: @business_unit_kind, business_unit_kind: { name: 'Regional' }
    }

    assert_redirected_to business_unit_kind_url(@business_unit_kind)
  end

  test 'should destroy business_unit_kind' do
    assert_difference 'BusinessUnitKind.count', -1 do
      delete :destroy, params: { id: @business_unit_kind }
    end

    assert_redirected_to business_unit_kinds_url
  end
end
