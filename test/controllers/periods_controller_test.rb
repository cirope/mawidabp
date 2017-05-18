require 'test_helper'

class PeriodsControllerTest < ActionController::TestCase
  setup do
    login

    @period = periods :current_period
  end

  test 'list periods' do
    get :index
    assert_response :success
    assert_not_nil assigns(:periods)
    assert_template 'periods/index'
  end

  test 'show period' do
    get :show, params: { id: @period }
    assert_response :success
    assert_not_nil assigns(:period)
    assert_template 'periods/show'
  end

  test 'new period' do
    get :new
    assert_response :success
    assert_not_nil assigns(:period)
    assert_template 'periods/new'
  end

  test 'create period' do
    assert_difference 'Period.count' do
      post :create, params: {
        period: {
          name: '20',
          description: 'New period',
          start: Date.today,
          end: 30.days.from_now.to_date,
        }
      }
    end
  end

  test 'back to redirection on create' do
    assert_difference 'Period.count' do
      session[:back_to] = new_period_url

      post :create, params: {
        period: {
          name: '20',
          description: 'New period',
          start: Date.today,
          end: 30.days.from_now.to_date,
        }
      }
    end

    assert_redirected_to action: :new
  end

  test 'edit period' do
    get :edit, params: { id: @period }
    assert_response :success
    assert_not_nil assigns(:period)
    assert_template 'periods/edit'
  end

  test 'update period' do
    assert_no_difference 'Period.count' do
      patch :update, params: {
        id: @period,
        period: {
          name: '20',
          description: 'Updated period',
          start: Date.today,
          end: 30.days.from_now.to_date,
        }
      }
    end

    assert_redirected_to periods_url
    assert_not_nil assigns(:period)
    assert_equal 'Updated period', assigns(:period).description
  end

  test 'destroy period' do
    assert_difference 'Period.count', -1 do
      delete :destroy, params: { id: periods(:unused_period).id }
    end

    assert_redirected_to periods_url
  end

  test 'destroy asociated period' do
    assert_no_difference 'Period.count' do
      delete :destroy, params: { id: @period }
    end

    assert_equal [
      I18n.t('periods.errors.can_not_be_destroyed'),
      I18n.t('periods.errors.reviews', count: @period.reviews.size),
      I18n.t('periods.errors.plans', count: @period.plans.size),
      I18n.t('periods.errors.workflows', count: @period.workflows.size)
    ].join(APP_ENUM_SEPARATOR), flash.alert
    assert_redirected_to periods_url
  end
end
