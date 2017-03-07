require 'test_helper'

# Pruebas para el controlador de planes
class PlansControllerTest < ActionController::TestCase
  fixtures :plans, :plan_items, :periods

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => plans(:current_plan).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list plans' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:plans)
    assert_template 'plans/index'
  end

  test 'show plan' do
    login
    get :show, :id => plans(:current_plan).id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_template 'plans/show'
  end

  test 'new plan' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_template 'plans/new'
  end

  test 'new plan with business unit type' do
    login
    get :new, :business_unit_type => business_unit_types(:cycle).to_param
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_template 'plans/new'
  end

  test 'clone plan' do
    login
    plan = Plan.find plans(:current_plan).id

    get :new, :clone_from => plan.id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert plan.plan_items.size > 0
    assert_equal plan.plan_items.size, assigns(:plan).plan_items.size
    assert plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum > 0
    assert_equal plan.plan_items.map { |pi| pi.resource_utilizations.size }.sum,
      assigns(:plan).plan_items.map { |pi| pi.resource_utilizations.size }.sum
    assert_template 'plans/new'
  end

  test 'create plan' do
    counts_array = ['Plan.count', 'PlanItem.count',
                    'ResourceUtilization.human.count',
                    'ResourceUtilization.material.count', 'Tagging.count']

    assert_difference counts_array do
      login
      post :create, {
        :plan => {
          :period_id => periods(:unused_period).id,
          :plan_items_attributes => [
            {
              :project => 'New project',
              :start => 71.days.from_now.to_date,
              :end => 80.days.from_now.to_date,
              :plain_predecessors => '',
              :order_number => 1,
              :business_unit_id => business_units(:business_unit_one).id,
              :resource_utilizations_attributes => [
                {
                  :resource_id => users(:bare_user).id,
                  :resource_type => 'User',
                  :units => '12.21'
                },
                {
                  :resource_id => resources(:laptop_resource).id,
                  :resource_type => 'Resource',
                  :units => '2'
                }
              ],
              :taggings_attributes => [
                {
                  :tag_id => tags(:extra).id
                }
              ]
            }
          ]
        }
      }
    end
  end

  test 'edit plan' do
    login
    get :edit, :id => plans(:past_plan).id
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_nil assigns(:business_unit_type)
    assert_template 'plans/edit'
  end

  test 'edit plan with business unit type' do
    login
    get :edit, :id => plans(:past_plan).id,
      :business_unit_type => business_unit_types(:cycle).to_param
    assert_response :success
    assert_not_nil assigns(:plan)
    assert_not_nil assigns(:business_unit_type)
    assert_template 'plans/edit'
  end

  test 'update plan' do
    assert_difference 'Tagging.count' do
      assert_no_difference ['Plan.count', 'ResourceUtilization.count'] do
        assert_difference 'PlanItem.count', -1 do
          login
          patch :update, {
            :id => plans(:past_plan).id,
            :plan => {
              :period_id => periods(:past_period).id,
              :new_version => '0',
              :plan_items_attributes => {
                '0' => {
                  :id => plan_items(:past_plan_item_1).id,
                  :project => 'Updated project',
                  :start => 55.days.ago.to_date,
                  :end => 45.days.ago.to_date,
                  :plain_predecessors => '',
                  :order_number => 1,
                  :business_unit_id => business_units(:business_unit_one).id,
                  :resource_utilizations_attributes => [
                    {
                      :id => resource_utilizations(:auditor_for_20_units_past_plan_item_1).id,
                      :resource_id => resources(:laptop_resource).id,
                      :resource_type => 'Resource',
                      :units => '12.21'
                    }
                  ],
                  :taggings_attributes => [
                    {
                      :tag_id => tags(:extra).id
                    }
                  ]
                },
                '1' => {
                  :id => plan_items(:past_plan_item_3).id,
                  :_destroy => '1'
                }
              }
            }
          }
        end
      end
    end

    resource_utilization = ResourceUtilization.find(
      resource_utilizations(:auditor_for_20_units_past_plan_item_1).id)

    assert_not_nil assigns(:plan)
    assert_redirected_to edit_plan_url(assigns(:plan))
    assert_equal 'Updated project', assigns(:plan).plan_items.find(
      plan_items(:past_plan_item_1).id).project
  end

  test 'overloaded plan' do
    values = {
      :plan => {
        :period_id => periods(:unused_period).id,
        :plan_items_attributes => [
          {
            :project => 'New project',
            :start => 71.days.from_now.to_date,
            :end => 80.days.from_now.to_date,
            :plain_predecessors => '',
            :order_number => 1,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          },
          {
            :project => 'New project 2',
            :start => 79.days.from_now.to_date,
            :end => 90.days.from_now.to_date,
            :plain_predecessors => '1',
            :order_number => 2,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          }
        ]
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      login
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
        :plan_items_attributes => [
          {
            :project => 'New project',
            :start => 71.days.from_now.to_date,
            :end => 80.days.from_now.to_date,
            :plain_predecessors => '',
            :order_number => 1,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          },
          {
            :project => 'New project',
            :start => 81.days.from_now.to_date,
            :end => 90.days.from_now.to_date,
            :plain_predecessors => '1',
            :order_number => 2,
            :business_unit_id => business_units(:business_unit_one).id,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:bare_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          }
        ]
      }
    }

    assert_no_difference ['Plan.count', 'PlanItem.count'] do
      login
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
    login
    assert_difference 'Plan.count', -1 do
      delete :destroy, :id => plans(:unrelated_plan).id
    end

    assert_redirected_to plans_url
  end

  test 'destroy related plan' do
    login
    assert_no_difference 'Plan.count' do
      delete :destroy, :id => plans(:current_plan).id
    end

    assert_equal I18n.t('plan.errors.can_not_be_destroyed'), flash.alert
    assert_redirected_to plans_url
  end

  test 'export to pdf' do
    login

    plan = Plan.find(plans(:current_plan).id)

    assert_nothing_raised { get :export_to_pdf, :id => plan.id }

    assert_redirected_to plan.relative_pdf_path
  end

  test 'auto complete for business_unit business_unit' do
    login
    get :auto_complete_for_business_unit, {
      :q => 'fifth', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_units.size # Fifth is in another organization

    get :auto_complete_for_business_unit, {
      :q => 'one', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_units.size # One only
    assert business_units.all? { |u| (u['label'] + u['informal']).match /one/i }

    get :auto_complete_for_business_unit, {
      :q => 'business', :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 4, business_units.size # All in the organization (one, two, three and four)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }

    get :auto_complete_for_business_unit, {
      :q => 'business',
      :business_unit_type_id => business_unit_types(:cycle).id,
      :format => :json
    }
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, business_units.size # All in the organization (one and two)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }
  end
end
