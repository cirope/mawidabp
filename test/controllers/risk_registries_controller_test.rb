#frozen_string_literal: true

require 'test_helper'

class RiskRegistriesControllerTest < ActionController::TestCase

  setup do
    @risk_registry = risk_registries :risk_registry

    login
  end

  test 'list risk registries' do
    get :index
    assert_response :success
    assert_not_nil assigns(:risk_registries)
    assert_template 'risk_registries/index'
  end

  test 'list risk registries with search' do
    login
    get :index, params: {
      search: {
        query: 'test',
        columns: ['name']
      }
    }
    assert_response :success
    assert_not_nil assigns(:risk_registries)
    assert_equal 1, assigns(:risk_registries).count
    assert_template 'risk_registries/index'
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create risk registry' do
    counts_array = [
      'RiskRegistry.count',
      'RiskCategory.count',
      'Risk.count'
    ]

    assert_difference counts_array, 1 do
      post :create, params: {
        risk_registry: {
          name: 'New name',
          description: 'New description',
          risk_categories_attributes: [
            name: 'New name',
            risks_attributes: [
              identifier: 'New identifier',
              name: 'New name',
              cause: 'New cause',
              effect: 'New effect',
              likelihood: 1,
              impact: 1,
              user_id: users(:administrator).id
            ]
          ]
        }
      }
    end

    assert_redirected_to edit_risk_registry_url(assigns(:risk_registry))
  end

  test 'should show risk registry' do
    get :show, params: { id: @risk_registry }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_registry }
    assert_response :success
  end

  test 'should update risk registry' do
    patch :update, params: {
      id: @risk_registry, risk_registry: { name: 'Name updated' }
    }
    assert_redirected_to risk_registry_url(assigns(:risk_registry))
  end

  test 'should destroy risk registry' do
    assert_difference 'RiskRegistry.count', -1 do
      delete :destroy, params: { id: @risk_registry }
    end

    assert_redirected_to risk_registries_url
  end
end
