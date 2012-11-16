require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  test 'public and private actions' do
    poll = polls(:poll_one)
    id_token = { :id => poll.to_param, :token => poll.access_token }
    id_param = {:id => poll.to_param}
    public_actions = [
      [:get, :edit, id_token],
      [:get, :show, id_param],
      [:put, :update, id_param],
    ]
    private_actions = [
      [:get, :index],
      [:get, :new],
      [:post, :create],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      if action.include? :update
        assert_response :redirect
      else
        assert_response :success
      end
    end
  end

  test 'list polls' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:polls)
    assert_select '#error_body', false
    assert_template 'polls/index'
  end

  test 'list reports' do
    perform_auth
    get :reports
    assert_response :success
    assert_not_nil assigns(:title)
    assert_select '#error_body', false
    assert_template 'polls/reports'
  end

  test 'show poll' do
    perform_auth
    get :show, :id => polls(:poll_one).id
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/show'
  end

  test 'new poll' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/new'
  end

  test "create poll" do
    perform_auth
    assert_difference 'Poll.count', ActionMailer::Base.deliveries.count do
      assert_difference 'Answer.count', 2 do
        post :create, {
          :poll => {
            :user_id => users(:poll_user).id,
            :questionnaire_id => questionnaires(:questionnaire_one).id,
            :organization_id => organizations(:default_organization).id,
            :access_token => SecureRandom.hex
          }
        }
      end
    end
    assert_redirected_to poll_path(assigns(:poll))
  end

  test 'edit poll' do
    poll = polls(:poll_one)
    get :edit, :id => poll.id, :token => poll.access_token
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/edit'
  end

  test "update poll" do
    assert_no_difference ['Poll.count'] do
      put :update, {
        :id => polls(:poll_one).id,
        :poll => {
          :comments => 'Encuesta actualizada'
        }
      }
    end
    assert_redirected_to poll_url(polls(:poll_one), :layout => 'application_clean')
    assert_not_nil assigns(:poll)
    assert_equal 'Encuesta actualizada', assigns(:poll).comments
    assert_equal true, assigns(:poll).answered
  end

  test 'destroy poll' do
    perform_auth
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        delete :destroy, :id => polls(:poll_one).id
      end
    end

    assert_redirected_to polls_url
  end

  test 'summary by questionnaire' do
    perform_auth

    get :summary_by_questionnaire
    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_questionnaire'

    assert_nothing_raised(Exception) do
      get :summary_by_questionnaire, :summary_by_questionnaire => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :questionnaire => questionnaires(:questionnaire_one).id
      }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_questionnaire'
  end

  test 'filtered questionnaire report' do
    perform_auth
    get :summary_by_questionnaire, :summary_by_questionnaire => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :questionnaire => questionnaires(:questionnaire_one).id
    }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:questionnaire)
    assert_not_nil assigns(:polls)
    assert_not_nil assigns(:answered)
    assert_not_nil assigns(:unanswered)
    assert_not_nil assigns(:rates)
    assert_template 'polls/summary_by_questionnaire'
  end

  test 'create summary by questionnaire' do
    perform_auth

    post :create_summary_by_questionnaire, :summary_by_questionnaire => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :questionnaire => questionnaires(:questionnaire_one).id
    },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to PDF::Writer.relative_path(I18n.t('poll.summary_pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)
  end

  test 'summary by business_unit' do
    perform_auth

    get :summary_by_business_unit
    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_business_unit'

    assert_nothing_raised(Exception) do
      get :summary_by_business_unit, :summary_by_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :questionnaire => questionnaires(:questionnaire_one).id,
        :business_unit_type => business_unit_types(:cycle).id
      }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_business_unit'
  end

  test 'filtered business unit report' do
    perform_auth
    get :summary_by_business_unit, :summary_by_business_unit => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :questionnaire => questionnaires(:questionnaire_one).id,
      :business_unit_type => business_unit_types(:cycle).id
    }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:questionnaire)
    assert_not_nil assigns(:questionnaires)
    assert_not_nil assigns(:from_date)
    assert_not_nil assigns(:to_date)
    assert_not_nil assigns(:business_unit_polls)
    assert_not_nil assigns(:selected_business_unit)
    assert_template 'polls/summary_by_business_unit'
  end

  test 'create summary by business unit' do
    perform_auth

    post :create_summary_by_business_unit, :summary_by_business_unit => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :questionnaire => questionnaires(:questionnaire_one).id,
      :business_unit_type => business_unit_types(:cycle).id
    },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to PDF::Writer.relative_path(I18n.t('poll.summary_pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)
  end
end
