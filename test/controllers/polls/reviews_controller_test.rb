require 'test_helper'

class Polls::ReviewsControllerTest < ActionController::TestCase
  setup do
    @questionnaire = questionnaires :questionnaire_one

    login
  end

  test 'report reviews' do
    get :index
    assert_response :success
    assert_template 'polls/reviews/index'

    assert_nothing_raised do
      get :index, params: { index: index_params.merge(answered: 'true') }
    end

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/reviews/index'
  end

  test 'filtered reviews report' do
    get :index, params: { index: index_params.merge(answered: nil) }

    assert_response :success
    assert_not_nil assigns(:report)
    assert_template 'polls/reviews/index'
  end

  test 'report reviews pdf' do
    get :index, xhr: true, params: {
      index: index_params.merge(answered: 'false'),
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_response :success
    assert_not_nil assigns(:report)
  end

  test 'report reviews as CSV' do
    get :index, params: {
      index: index_params.merge(answered: 'true')
    }, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
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
