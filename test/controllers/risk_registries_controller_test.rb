require 'test_helper'

class RiskRegistriesControllerTest < ActionController::TestCase

  setup do
    @risk_registry = risk_registries(:one)

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:risk_registries)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create risk_registry' do
    assert_difference 'RiskRegistry.count' do
      post :create, params: {
        risk_registry: {
          name: nil, description: nil
        }
      }
    end

    assert_redirected_to risk_registry_url(assigns(:risk_registry))
  end

  test 'should show risk_registry' do
    get :show, params: { id: @risk_registry }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_registry }
    assert_response :success
  end

  test 'should update risk_registry' do
    patch :update, params: {
      id: @risk_registry, risk_registry: { attr: 'value' }
    }
    assert_redirected_to risk_registry_url(assigns(:risk_registry))
  end

  test 'should destroy risk_registry' do
    assert_difference 'RiskRegistry.count', -1 do
      delete :destroy, params: { id: @risk_registry }
    end

    assert_redirected_to risk_registries_url
  end
end
