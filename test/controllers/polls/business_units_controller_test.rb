require 'test_helper'

class Polls::BusinessUnitsControllerTest < ActionController::TestCase
  setup do
    @business_unit_type = business_unit_types :cycle
    @questionnaire = questionnaires :questionnaire_one

    login
  end

  test 'report business_unit' do
    get :index
    assert_response :success
    assert_template 'polls/business_units/index'

    assert_nothing_raised do
      get :index, params: { index: index_params }
    end

    assert_response :success
    assert_template 'polls/business_units/index'
  end

  test 'filtered business unit report' do
    get :index, params: { index: index_params }

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/business_units/index'
  end

  test 'report business unit pdf' do
    get :index, xhr: true, params: {
      index: index_params,
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_response :success
  end

  private

    def index_params
      {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date,
        questionnaire: @questionnaire,
        business_unit_type: @business_unit_type
      }
    end
end
