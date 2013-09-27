require 'test_helper'

# Pruebas para el controlador de programas de trabajo
class WorkflowsControllerTest < ActionController::TestCase
  fixtures :workflows, :workflow_items, :periods, :reviews, :organizations

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => workflows(:current_workflow).to_param}
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
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list workflows' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:workflows)
    assert_select '#error_body', false
    assert_template 'workflows/index'
  end

  test 'show workflow' do
    perform_auth
    get :show, :id => workflows(:current_workflow).id
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_select '#error_body', false
    assert_template 'workflows/show'
  end

  test 'new workflow' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_select '#error_body', false
    assert_template 'workflows/new'
  end

  test 'clone workflow' do
    perform_auth
    workflow = Workflow.find workflows(:current_workflow).id

    get :new, :clone_from => workflow.id
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert workflow.workflow_items.size > 0
    assert_equal workflow.workflow_items.size,
      assigns(:workflow).workflow_items.size
    assert workflow.workflow_items.map { |pi| pi.resource_utilizations.size }.sum > 0
    assert_equal workflow.workflow_items.map { |pi| pi.resource_utilizations.size }.sum,
      assigns(:workflow).workflow_items.map { |pi| pi.resource_utilizations.size }.sum
    assert_select '#error_body', false
    assert_template 'workflows/new'
  end

  test 'create workflow' do
    counts_array = ['Workflow.count', 'WorkflowItem.count',
      'ResourceUtilization.material.count', 'ResourceUtilization.human.count']

    assert_difference counts_array do
      perform_auth
      post :create, {
        :workflow => {
          :period_id => periods(:current_period).id,
          :review_id => reviews(:review_without_conclusion).id,
          :workflow_items_attributes => {
            :new_1 => {
              :task => 'New task',
              :start => Date.today,
              :end => 10.days.from_now.to_date,
              :plain_predecessors => '',
              :order_number => 1,
              :resource_utilizations_attributes => {
                :new_1 => {
                  :resource_id => users(:manager_user).id,
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

  test 'edit workflow' do
    perform_auth
    get :edit, :id => workflows(:current_workflow).id
    assert_response :success
    assert_not_nil assigns(:workflow)
    assert_select '#error_body', false
    assert_template 'workflows/edit'
  end

  test 'update workflow' do
    assert_no_difference ['Workflow.count', 'ResourceUtilization.count'] do
      assert_difference 'WorkflowItem.count', -1 do
        perform_auth
        patch :update, {
          :id => workflows(:with_conclusion_workflow).id,
          :workflow => {
            :period_id => periods(:current_period).id,
            :review_id => reviews(:review_with_conclusion).id,
            :workflow_items_attributes => {
              workflow_items(:with_conclusion_workflow_item_1).id => {
                :id => workflow_items(:with_conclusion_workflow_item_1).id,
                :task => 'Updated task',
                :start => 5.days.ago.to_date,
                :end => 2.days.ago.to_date,
                :plain_predecessors => '',
                :order_number => 1,
                :resource_utilizations_attributes => {
                  resource_utilizations(:auditor_for_20_units_with_conclusion_workflow_item_1).id => {
                    :id => resource_utilizations(:auditor_for_20_units_with_conclusion_workflow_item_1).id,
                    :resource_id => users(:manager_user).id,
                    :units => '12.21',
                    :cost_per_unit => '8.75'
                  }
                }
              },
              workflow_items(:with_conclusion_workflow_item_3).id => {
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
    assert_in_delta 8.75, resource_utilization.cost_per_unit, 0.01
  end

  test 'overloaded workflow' do
    values = {
      :workflow => {
        :period_id => periods(:current_period).id,
        :review_id => reviews(:review_without_conclusion).id,
        :workflow_items_attributes => {
          :new_1 => {
            :task => 'New task',
            :start => Date.today,
            :end => 5.days.from_now.to_date,
            :plain_predecessors => '',
            :order_number => 1,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:manager_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          },
          :new_2 => {
            :task => 'New task 2',
            :start => 4.days.from_now.to_date,
            :end => 10.days.from_now.to_date,
            :plain_predecessors => '1',
            :order_number => 2,
            :resource_utilizations_attributes => {
              :new_1 => {
                :resource_id => users(:manager_user).id,
                :resource_type => 'User',
                :units => '12.21',
                :cost_per_unit => '8.75'
              }
            }
          }
        }
      }
    }

    assert_no_difference ['Workflow.count', 'WorkflowItem.count'] do
      perform_auth
      post :create, values
    end

    assert_difference 'WorkflowItem.count', 2 do
      assert_difference 'Workflow.count' do
        values[:workflow][:allow_overload] = '1'
        post :create, values
      end
    end
  end

  test 'destroy workflow' do
    perform_auth
    assert_difference 'Workflow.count', -1 do
      delete :destroy, :id => workflows(:with_conclusion_workflow).id
    end

    assert_redirected_to workflows_url
  end

  test 'export to pdf' do
    perform_auth

    workflow = Workflow.find(workflows(:current_workflow).id)

    assert_nothing_raised(Exception) { get :export_to_pdf, :id => workflow.id }

    assert_redirected_to workflow.relative_pdf_path
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :q => 'admin', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, users.size # Administrator
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :auto_complete_for_user, { :q=> 'blank', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 2, users.size # Blank and Expired blank
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }

    get :auto_complete_for_user, { :q => 'xyz', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 0, users.size # None
  end

  test 'reviews for period' do
    perform_auth
    get :reviews_for_period, :period => periods(:current_period).id
    assert_response :success

    reviews = nil

    assert_nothing_raised(Exception) do
      reviews = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil reviews
    assert_not_equal 0, reviews.size
    assert_not_nil reviews.any? {|r| r.first == reviews(:current_review).identification}
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
    assert_not_nil resource_data['cost_per_unit']
  end

  test 'estimated amount' do
    perform_auth
    get :estimated_amount, :id => reviews(:current_review).id

    assert_response :success
    assert_select '#error_body', false
    assert_template 'workflows/_estimated_amount'
  end
end
