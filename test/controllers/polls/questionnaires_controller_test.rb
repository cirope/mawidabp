require 'test_helper'

class Polls::QuestionnairesControllerTest < ActionController::TestCase
  setup do
    @questionnaire = questionnaires :questionnaire_one

    login
  end

  test 'index polls questionnaires' do
    get :index
    assert_response :success
    assert_template 'polls/questionnaires/index'

    assert_nothing_raised do
      get :index, params: { index: index_params }
    end

    assert_response :success
    assert_not_nil assigns(:report)
  end

  test 'filtered questionnaire report' do
    get :index, params: { index: index_params }

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/questionnaires/index'
  end

  test 'report questionnaire pdf' do
    get :index, params: {
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
        date_field: %w(created_at issue_date).sample,
        questionnaire: @questionnaire
      }
    end
end
