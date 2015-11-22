require 'test_helper'

class Polls::AnswersControllerTest < ActionController::TestCase
  setup do
    @questionnaire = questionnaires :questionnaire_one

    login
  end

  test 'report answers' do
    get :index
    assert_response :success
    assert_template 'polls/answers/index'

    assert_nothing_raised do
      get :index, index: index_params.merge(answered: 'true')
    end

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/answers/index'
  end

  test 'filtered answers report' do
    get :index, index: index_params.merge(answered: nil)

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/answers/index'
  end

  test 'report answers pdf' do
    xhr :get, :index, index: index_params.merge(answered: 'false'),
      report_title: 'New title', report_subtitle: 'New subtitle'

    assert_response :success
    assert_not_nil assigns(:report)
  end

  private

    def index_params
      {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date,
        questionnaire: @questionnaire
      }
    end
end
