require 'test_helper'

# Pruebas para el controlador de periodos
class PeriodsControllerTest < ActionController::TestCase
  fixtures :periods, :organizations

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => periods(:current_period).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:put, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list periods' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:periods)
    assert_select '#error_body', false
    assert_template 'periods/index'
  end

  test 'show period' do
    perform_auth
    get :show, :id => periods(:current_period).id
    assert_response :success
    assert_not_nil assigns(:period)
    assert_select '#error_body', false
    assert_template 'periods/show'
  end

  test 'new period' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:period)
    assert_select '#error_body', false
    assert_template 'periods/new'
  end

  test 'create period' do
    perform_auth
    assert_difference 'Period.count' do
      post :create, {
        :period => {
          :number => '20',
          :description => 'New period',
          :start => Date.today,
          :end => 30.days.from_now.to_date,
          :organization_id => organizations(:default_organization).id
        }
      }
    end
  end

  test 'back to redirection on create' do
    assert_difference 'Period.count' do
      perform_auth
      session[:back_to] = new_period_url
      
      post :create, {
        :period => {
          :number => '20',
          :description => 'New period',
          :start => Date.today,
          :end => 30.days.from_now.to_date,
          :organization_id => organizations(:default_organization).id
        }
      }
    end

    assert_redirected_to :action => :new
  end

  test 'edit period' do
    perform_auth
    get :edit, :id => periods(:current_period).id
    assert_response :success
    assert_not_nil assigns(:period)
    assert_select '#error_body', false
    assert_template 'periods/edit'
  end

  test 'update period' do
    assert_no_difference 'Period.count' do
      perform_auth
      put :update, {
        :id => periods(:current_period).id,
        :period => {
            :number => '20',
            :description => 'Updated period',
            :start => Date.today,
            :end => 30.days.from_now.to_date,
            :organization_id => organizations(:default_organization).id
        }
      }
    end

    assert_redirected_to periods_url
    assert_not_nil assigns(:period)
    assert_equal 'Updated period', assigns(:period).description
  end

  test 'destroy period' do
    perform_auth
    assert_difference 'Period.count', -1 do
      delete :destroy, :id => periods(:unused_period).id
    end

    assert_redirected_to periods_url
  end

  test 'destroy asociated period' do
    perform_auth
    period = Period.find periods(:current_period).id
    assert_no_difference 'Period.count' do
      delete :destroy, :id => period.id
    end

    assert_equal [I18n.t(:'period.errors.can_not_be_destroyed'),
      I18n.t(:'period.errors.has_reviews', :count => period.reviews.size),
      I18n.t(:'period.errors.has_plans', :count => period.plans.size),
      I18n.t(:'period.errors.has_workflows', :count => period.workflows.size),
      I18n.t(:'period.errors.has_procedure_controls',
        :count => period.procedure_controls.size)].join(APP_ENUM_SEPARATOR),
      flash.alert
    assert_redirected_to periods_url
  end
end