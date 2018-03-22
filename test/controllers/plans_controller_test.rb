require 'test_helper'

class PlansControllerTest < ActionController::TestCase
  setup do
    @plan = plans :current_plan

    login
  end

  test 'list plans' do
    get :index
    assert_response :success
  end

  test 'show plan' do
    get :show, params: { id: @plan }
    assert_response :success
  end

  test 'show plan on pdf' do
    get :show, params: { id: @plan }, as: :pdf
    assert_redirected_to @plan.relative_pdf_path
  end

  test 'show plan on js' do
    business_unit_type = business_unit_types :cycle

    get :show, params: {
      id: @plan,
      business_unit_type: business_unit_type
    }, xhr: true, as: :js

    assert_response :success
  end

  test 'new plan' do
    get :new
    assert_response :success
  end

  test 'clone plan' do
    get :new, params: { clone_from: @plan }
    assert_response :success
    assert @plan.plan_items.size > 0
    assert_equal @plan.plan_items.size, assigns(:plan).plan_items.size
    assert @plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum > 0
    assert_equal @plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum,
      assigns(:plan).plan_items.map { |pi| pi.resource_utilizations.size }.sum
  end

  test 'create plan' do
    counts_array = [
      'Plan.count',
      'PlanItem.count',
      'ResourceUtilization.human.count',
      'ResourceUtilization.material.count',
      'Tagging.count'
    ]

    assert_difference counts_array do
      post :create, params: {
        plan: {
          period_id: periods(:unused_period).id,
          plan_items_attributes: [
            {
              project: 'New project',
              start: 71.days.from_now.to_date,
              end: 80.days.from_now.to_date,
              order_number: 1,
              scope: 'committee',
              risk_exposure: 'high',
              business_unit_id: business_units(:business_unit_one).id,
              resource_utilizations_attributes: [
                {
                  resource_id: users(:bare).id,
                  resource_type: 'User',
                  units: '12.21'
                },
                {
                  resource_id: resources(:laptop_resource).id,
                  resource_type: 'Resource',
                  units: '2'
                }
              ],
              taggings_attributes: [
                {
                  tag_id: tags(:extra).id
                }
              ]
            }
          ]
        }
      }
    end
  end

  test 'edit plan' do
    get :edit, params: { id: @plan }
    assert_response :success
  end

  test 'edit plan with business unit type' do
    business_unit_type = business_unit_types :cycle

    get :edit, params: {
      id: @plan,
      business_unit_type: business_unit_type
    }
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_not_nil assigns(:business_unit_type)
  end

  test 'update plan' do
    plan = plans :past_plan

    assert_difference 'Tagging.count' do
      assert_no_difference ['Plan.count', 'ResourceUtilization.count'] do
        assert_difference 'PlanItem.count', -1 do
          patch :update, params: {
            id: plan,
            plan: {
              period_id: periods(:past_period).id,
              new_version: '0',
              plan_items_attributes: {
                '0' => {
                  id: plan_items(:past_plan_item_1).id,
                  project: 'Updated project',
                  start: 55.days.ago.to_date,
                  end: 45.days.ago.to_date,
                  order_number: 1,
                  scope: 'committee',
                  risk_exposure: 'high',
                  business_unit_id: business_units(:business_unit_one).id,
                  resource_utilizations_attributes: {
                    '1' => {
                      id: resource_utilizations(:auditor_for_20_units_past_plan_item_1).id,
                      resource_id: resources(:laptop_resource).id,
                      resource_type: 'Resource',
                      units: '12.21'
                    }
                  },
                  taggings_attributes: [
                    {
                      tag_id: tags(:extra).id
                    }
                  ]
                },
                '1' => {
                  id: plan_items(:past_plan_item_3).id,
                  _destroy: '1'
                }
              }
            }
          }
        end
      end
    end

    resource_utilization = resource_utilizations :auditor_for_20_units_past_plan_item_1

    assert_redirected_to edit_plan_url(plan)
    assert_equal 'Updated project', plan.reload.plan_items.find(
      plan_items(:past_plan_item_1).id
    ).project
  end

  test 'overloaded plan' do
    values = {
      plan: {
        period_id: periods(:unused_period).id,
        plan_items_attributes: [
          {
            project: 'New project',
            start: 71.days.from_now.to_date,
            end: 80.days.from_now.to_date,
            order_number: 1,
            scope: 'committee',
            risk_exposure: 'high',
            business_unit_id: business_units(:business_unit_one).id,
            resource_utilizations_attributes: [
              {
                resource_id: users(:bare).id,
                resource_type: 'User',
                units: '12.21'
              }
            ]
          },
          {
            project: 'New project 2',
            start: 79.days.from_now.to_date,
            end: 90.days.from_now.to_date,
            order_number: 2,
            scope: 'committee',
            risk_exposure: 'high',
            business_unit_id: business_units(:business_unit_one).id,
            resource_utilizations_attributes: [
              {
                resource_id: users(:bare).id,
                resource_type: 'User',
                units: '12.21'
              }
            ]
          }
        ]
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      post :create, params: values
    end

    assert_difference 'PlanItem.count', 2 do
      assert_difference 'Plan.count' do
        values[:plan][:allow_overload] = '1'
        post :create, params: values
      end
    end
  end

  test 'plan with duplicated projects' do
    values = {
      plan: {
        period_id: periods(:unused_period).id,
        plan_items_attributes: [
          {
            project: 'New project',
            start: 71.days.from_now.to_date,
            end: 80.days.from_now.to_date,
            order_number: 1,
            scope: 'committee',
            risk_exposure: 'high',
            business_unit_id: business_units(:business_unit_one).id,
            resource_utilizations_attributes: [
              {
                resource_id: users(:bare).id,
                resource_type: 'User',
                units: '12.21'
              }
            ]
          },
          {
            project: 'New project',
            start: 81.days.from_now.to_date,
            end: 90.days.from_now.to_date,
            order_number: 2,
            scope: 'committee',
            risk_exposure: 'high',
            business_unit_id: business_units(:business_unit_one).id,
            resource_utilizations_attributes: [
              {
                resource_id: users(:bare).id,
                resource_type: 'User',
                units: '12.21'
              }
            ]
          }
        ]
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      post :create, params: values
    end

    assert_difference 'PlanItem.count', 2 do
      assert_difference 'Plan.count' do
        values[:plan][:allow_duplication] = '1'
        post :create, params: values
      end
    end
  end

  test 'destroy plan' do
    assert_difference 'Plan.count', -1 do
      delete :destroy, params: { id: plans(:unrelated_plan) }
    end

    assert_redirected_to plans_url
  end

  test 'destroy related plan' do
    assert_no_difference 'Plan.count' do
      delete :destroy, params: { id: plans(:current_plan) }
    end

    assert_redirected_to plans_url
  end

  test 'auto complete for business_unit business_unit' do
    get :auto_complete_for_business_unit, params: { q: 'fifth' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_units.size # Fifth is in another organization

    get :auto_complete_for_business_unit, params: { q: 'one' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_units.size # One only
    assert business_units.all? { |u| (u['label'] + u['informal']).match /one/i }

    get :auto_complete_for_business_unit, params: { q: 'business' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 4, business_units.size # All in the organization (one, two, three and four)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }

    get :auto_complete_for_business_unit, params: {
      q: 'business',
      business_unit_type_id: business_unit_types(:cycle).id
    }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, business_units.size # All in the organization (one and two)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }
  end
end
