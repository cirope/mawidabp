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
          date: date.to_fs(:db),
          amount: '1',
          resource_id: reviews(:current_review).id,
          resource_type: 'Review'
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

  test 'time summary filter by default user' do
    user = users :administrator

    get :index, params: {
      start_date: 1.weeks.ago,
      end_date: 1.weeks.since
    }

    assert_response :success
    assert_select 'body h2',
      "#{I18n.t('time_summary.index.title')} | #{user.full_name}"
  end

  test 'time summary filter by user descendants' do
    user            = users :administrator
    user_descendant = user.self_and_descendants.first

    get :index, params: {
      start_date: 1.weeks.ago,
      end_date: 1.weeks.since,
      user_id: user_descendant.id
    }

    assert_response :success
    assert_select 'body h2',
      "#{I18n.t('time_summary.index.title')} | #{user_descendant.full_name}"
  end

  test 'time summary show' do
    get :show, xhr: true, params: {
      id: reviews(:current_review)
    }, as: :js

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end
end
