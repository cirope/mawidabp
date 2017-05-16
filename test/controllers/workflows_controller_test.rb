require 'test_helper'

# Pruebas para el controlador de programas de trabajo
class WorkflowsControllerTest < ActionController::TestCase
  fixtures :workflows, :workflow_items, :periods, :reviews, :organizations

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      :params => {
        :id => workflows(:current_workflow).to_param
      }
    }
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

  test 'list workflows' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:workflows)
    assert_template 'workflows/index'
  end

  test 'show workflow' do
    login
    get :show, :params => { :id => workflows(:current_workflow).id }
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_template 'workflows/show'
  end

  test 'new workflow' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_template 'workflows/new'
  end

  test 'clone workflow' do
    login
    workflow = Workflow.find workflows(:current_workflow).id

    get :new, :params => { :clone_from => workflow.id }
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert workflow.workflow_items.size > 0
    assert_equal workflow.workflow_items.size,
      assigns(:workflow).workflow_items.size
    assert workflow.workflow_items.map { |pi| pi.resource_utilizations.size }.sum > 0
    assert_equal workflow.workflow_items.map { |pi| pi.resource_utilizations.size }.sum,
      assigns(:workflow).workflow_items.map { |pi| pi.resource_utilizations.size }.sum
    assert_template 'workflows/new'
  end

  test 'create workflow' do
    counts_array = ['Workflow.count', 'WorkflowItem.count',
      'ResourceUtilization.material.count', 'ResourceUtilization.human.count']

    assert_difference counts_array do
      login
      post :create, :params => {
        :workflow => {
          :period_id => periods(:current_period).id,
          :review_id => reviews(:review_without_conclusion).id,
          :workflow_items_attributes => [
            {
              :task => 'New task',
              :start => Date.today,
              :end => 10.days.from_now.to_date,
              :order_number => 1,
              :resource_utilizations_attributes => [
                {
                  :resource_id => users(:manager_user).id,
                  :resource_type => 'User',
                  :units => '12.21'
                }, {
                  :resource_id => resources(:laptop_resource).id,
                  :resource_type => 'Resource',
                  :units => '2'
                }
              ]
            }
          ]
        }
      }
    end
  end

  test 'edit workflow' do
    login
    get :edit, params: { :id => workflows(:current_workflow).id }
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_template 'workflows/edit'
  end

  test 'update workflow' do
    assert_no_difference ['Workflow.count', 'ResourceUtilization.count'] do
      assert_difference 'WorkflowItem.count', -1 do
        login
        patch :update, :params => {
          :id => workflows(:with_conclusion_workflow).id,
          :workflow => {
            :period_id => periods(:current_period).id,
            :review_id => reviews(:review_with_conclusion).id,
            :workflow_items_attributes => {
              '0' => {
                :id => workflow_items(:with_conclusion_workflow_item_1).id,
                :task => 'Updated task',
                :start => 5.days.ago.to_date,
                :end => 2.days.ago.to_date,
                :order_number => 1,
                :resource_utilizations_attributes => [
                  {
                    :id => resource_utilizations(:auditor_for_20_units_with_conclusion_workflow_item_1).id,
                    :resource_id => users(:manager_user).id,
                    :units => '12.21'
                  }
                ]
              },
              '1' => {
                :id => workflow_items(:with_conclusion_workflow_item_3).id,
                :_destroy => 1
              }
            }
          }
        }
      end
    end

    resource_utilization = ResourceUtilization.find(
      resource_utilizations(:auditor_for_20_units_with_conclusion_workflow_item_1).id)

    assert_redirected_to workflows_url
    assert_not_nil assigns(:workflow)
    assert_equal 'Updated task', assigns(:workflow).workflow_items.find(
      workflow_items(:with_conclusion_workflow_item_1).id).task
  end

  test 'overloaded workflow' do
    values = {
      :workflow => {
        :period_id => periods(:current_period).id,
        :review_id => reviews(:review_without_conclusion).id,
        :workflow_items_attributes => [
          {
            :task => 'New task',
            :start => Date.today,
            :end => 5.days.from_now.to_date,
            :order_number => 1,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:manager_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          }, {
            :task => 'New task 2',
            :start => 4.days.from_now.to_date,
            :end => 10.days.from_now.to_date,
            :order_number => 2,
            :resource_utilizations_attributes => [
              {
                :resource_id => users(:manager_user).id,
                :resource_type => 'User',
                :units => '12.21'
              }
            ]
          }
        ]
      }
    }

    assert_no_difference ['Workflow.count', 'WorkflowItem.count'] do
      login
      post :create, :params => values
    end

    assert_difference 'WorkflowItem.count', 2 do
      assert_difference 'Workflow.count' do
        values[:workflow][:allow_overload] = '1'
        post :create, :params => values
      end
    end
  end

  test 'destroy workflow' do
    login
    assert_difference 'Workflow.count', -1 do
      delete :destroy, :params => {
        :id => workflows(:with_conclusion_workflow).id
      }
    end

    assert_redirected_to workflows_url
  end

  test 'export to pdf' do
    login

    workflow = Workflow.find(workflows(:current_workflow).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => { :id => workflow.id }
    end

    assert_redirected_to workflow.relative_pdf_path
  end

  test 'reviews for period' do
    login
    get :reviews_for_period, :params => {
      :period => periods(:current_period).id
    }
    assert_response :success

    reviews = nil

    assert_nothing_raised do
      reviews = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil reviews
    assert_not_equal 0, reviews.size
    assert_not_nil reviews.any? {|r| r.first == reviews(:current_review).identification}
  end

  test 'estimated amount' do
    login
    get :estimated_amount, :params => {
      :id => reviews(:current_review).id
    }

    assert_response :success
    assert_template 'workflows/_estimated_amount'
  end
end
