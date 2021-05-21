require 'test_helper'

class TimeSummaryControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'should get index' do
    get :index

    assert_response :success
  end

  test 'should get new' do
    get :new, params: { date: Time.zone.today }

    assert_response :success
  end

  test 'should create time consumption' do
    date = Time.zone.today

    assert_difference %w(TimeConsumption.count) do
      post :create, params: {
        time_consumption: {
          date: date.to_s(:db),
          amount: '1',
          activity_id: activities(:special_activity).id
        }
      }
    end

    assert_redirected_to time_summary_index_url(
      start_date: date.at_beginning_of_week,
      end_date:   date.at_end_of_week
    )
  end

  test 'time summary report as CSV' do
    ['weeks', 'month', 'year'].map do |period|
      get :index, params: {
        start_date: 1.send(period).ago,
        end_date: 1.send(period).since
      }, as: :csv

      assert_response :success
      assert_match Mime[:csv].to_s, @response.content_type
    end
  end
end
