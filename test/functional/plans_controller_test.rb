require 'test_helper'

# Pruebas para el controlador de planes
class PlansControllerTest < ActionController::TestCase
  fixtures :plans, :plan_items, :periods

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:alert]
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list plans' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:plans)
    assert_select '#error_body', false
    assert_template 'plans/index'
  end

  test 'show plan' do
    perform_auth
    get :show, :id => plans(:current_plan).id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_select '#error_body', false
    assert_template 'plans/show'
  end

  test 'new plan' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_select '#error_body', false
    assert_template 'plans/new'
  end

  test 'clone plan' do
    perform_auth
    plan = Plan.find plans(:current_plan).id

    get :new, :clone_from => plan.id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert plan.plan_items.size > 0
    assert_equal plan.plan_items.size, assigns(:plan).plan_items.size
    assert plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum > 0
    assert_equal plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum,
      assigns(:plan).plan_items.map { |pi| pi.resource_utilizations.size }.sum
    assert_select '#error_body', false
    assert_template 'plans/new'
  end

  test 'create plan' do
    counts_array = ['Plan.count', 'PlanItem.count',
      'ResourceUtilization.human.count', 'ResourceUtilization.material.count']

    assert_difference counts_array do
      perform_auth
      post :create, {
        :plan => {
          :period_id => periods(:unused_period).id,
          :plan_items_attributes => {
            :new_1 => {
              :project => 'New project',
              :start => 71.days.from_now.to_date,
              :end => 80.days.from_now.to_date,
              :plain_predecessors => '',
              :order_number => 1,
              :business_unit_id => business_units(:business_unit_one).id,
              :resource_utilizations_attributes => {
                :new_1 => {
                  :resource_id => users(:bare_user).id,
                  :resource_type => 'User',
                  :units => '12.21',
                  :cost_per_unit => '8.75'
                },
                :new_2 => {
                  :resource_id => resources(:laptop_resource).id,
                  :resource_type => 'Resource',
                  :units => '2',
                  :cost_per_unit => '10.7'
                }
              }
            }
          }
        }
      }
    end
  end

  test 'edit plan' do
    perform_auth
    get :edit, :id => plans(:past_plan).id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_select '#error_body', false, response_from_page_or_rjs
    assert_template 'plans/edit'
  end

  test 'update plan' do
    assert_no_difference ['Plan.count', 'ResourceUtilization.count'] do
      assert_difference 'PlanItem.count', -1 do
        perform_auth
        put :update, {
          :id => plans(:past_plan).id,
          :plan => {
            :period_id => periods(:past_period).id,
            :new_version => '0',
            :plan_items_attributes => {
              plan_items(:past_plan_item_1).id => {
                :id => plan_items(:past_plan_item_1).id,
                :project => 'Updated project',
                :start => 55.days.ago.to_date,
                :end => 45.days.ago.to_date,
                :plain_predecessors => '',
                :order_number => 1,
                :business_unit_id => business_units(:business_unit_one).id,
                :resource_utilizations_attributes => {
                  resource_utilizations(:auditor_for_20_units_past_plan_item_1).id => {
                    :id => resource_utilizations(:auditor_for_20_units_past_plan_item_1).id,
                    :resource_id => resources(:laptop_resource).id,
                    :resource_type => 'Resource',
                    :units => '12.21',
                    :cost_per_unit => '8.75'
                  }
                }
              },
              plan_items(:past_plan_item_3).id => {
                :id => plan_items(:past_plan_item_3).id,
                :_destroy => '1'
              }
            }
          }
        }
      end
    end

    resource_utilization = ResourceUtilization.find(
      resource_utilizations(:auditor_for_20_units_past_plan_item_1).id)

    assert_redirected_to plans_path
    assert_not_nil assigns(:plan)
    assert_equal 'Updated project', assigns(:plan).plan_items.find(
      plan_items(:past_plan_item_1).id).project
    assert_in_delta 8.75, resource_utilization.cost_per_unit, 0.01
  end

  test 'overloaded plan' do
    values = {
      :plan => {
        :period_id => periods(:unused_period).id,
        :plan_items_attributes => {
          :new_1 => {
            :project => 'New project',
            :start => 71.days.from_now.to_date,
            :end => 80.days.from_now.to_date,
            :plain_predecessors => '',
            :order_number => 1,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          },
          :new_2 => {
            :project => 'New project 2',
            :start => 79.days.from_now.to_date,
            :end => 90.days.from_now.to_date,
            :plain_predecessors => '1',
            :order_number => 2,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          }
        }
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      perform_auth
      post :create, values
    end

    assert_difference 'PlanItem.count', 2 do
      assert_difference 'Plan.count' do
        values[:plan][:allow_overload] = '1'
        post :create, values
      end
    end
  end

  test 'plan with duplicated projects' do
    values = {
      :plan => {
        :period_id => periods(:unused_period).id,
        :plan_items_attributes => {
          :new_1 => {
            :project => 'New project',
            :start => 71.days.from_now.to_date,
            :end => 80.days.from_now.to_date,
            :plain_predecessors => '',
            :order_number => 1,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          },
          :new_2 => {
            :project => 'New project',
            :start => 81.days.from_now.to_date,
            :end => 90.days.from_now.to_date,
            :plain_predecessors => '1',
            :order_number => 2,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          }
        }
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      perform_auth
      post :create, values
    end

    assert_difference 'PlanItem.count', 2 do
      assert_difference 'Plan.count' do
        values[:plan][:allow_duplication] = '1'
        post :create, values
      end
    end
  end

  test 'destroy plan' do
    perform_auth
    assert_difference 'Plan.count', -1 do
      delete :destroy, :id => plans(:unrelated_plan).id
    end

    assert_redirected_to plans_path
  end

  test 'destroy related plan' do
    perform_auth
    assert_no_difference 'Plan.count' do
      delete :destroy, :id => plans(:current_plan).id
    end

    assert_equal I18n.t(:'plan.errors.can_not_be_destroyed'), flash[:alert]
    assert_redirected_to plans_path
  end

  test 'export to pdf' do
    perform_auth

    plan = Plan.find(plans(:current_plan).id)

    assert_nothing_raised(Exception) { get :export_to_pdf, :id => plan.id }

    assert_redirected_to plan.relative_pdf_path
  end

  test 'auto complete for business_unit business_unit' do
    perform_auth
    post :auto_complete_for_business_unit_business_unit_id, {
      :business_unit_data => 'fifth'
    }
    assert_response :success
    assert_not_nil assigns(:business_units)
    assert_equal 0, assigns(:business_units).size # Fifth is in another organization
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_business_unit_business_unit_id'

    post :auto_complete_for_business_unit_business_unit_id, {
      :business_unit_data => 'one'
    }
    assert_response :success
    assert_not_nil assigns(:business_units)
    assert_equal 1, assigns(:business_units).size # One only
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_business_unit_business_unit_id'

    post :auto_complete_for_business_unit_business_unit_id, {
      :business_unit_data => 'business'
    }
    assert_response :success
    assert_not_nil assigns(:business_units)
    assert_equal 4, assigns(:business_units).size # All in the organization (one, two, three and four)
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_business_unit_business_unit_id'
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'admin' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Administrator
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'blank' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size # Blank and Expired blank
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'xyz' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # None
    assert_select '#error_body', false
    assert_template 'plans/auto_complete_for_user'
  end

  test 'resource data' do
    perform_auth

    resource_data = nil

    xhr :get, :resource_data, :id => resources(:auditor_resource).id
    assert_response :success
    assert_nothing_raised(Exception) do
      resource_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil resource_data
    assert_not_nil resource_data['resource']
    assert_not_nil resource_data['resource']['cost_per_unit']
  end
end