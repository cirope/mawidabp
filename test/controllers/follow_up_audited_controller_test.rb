require 'test_helper'

class FollowUpAuditedControllerTest < ActionController::TestCase

  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :weaknesses_by_user
    ]

    private_actions.each do |action|
      get action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list reports' do
    login user: users(:coordinator_manager)
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'follow_up_audited/index'
  end

  test 'weaknesses by user' do
    login user: users(:coordinator_manager)

    get :weaknesses_by_user
    assert_response :success
    assert_template 'follow_up_audited/weaknesses_by_user'

    assert_nothing_raised do
      get :weaknesses_by_user, :params => {
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audited/weaknesses_by_user'
  end

  test 'weaknesses by user as CSV' do
    login user: users(:coordinator_manager)

    get :weaknesses_by_user, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_by_user, :params => {
        :controller_name => 'follow_up',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses by user' do
    login user: users(:coordinator_manager)

    get :weaknesses_by_user, :params => {
      :weaknesses_by_user => {
        :risk => ['', '1', '2'],
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :user_id => users(:audited).id.to_s
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audited/weaknesses_by_user'
  end

  test 'create weaknesses by user' do
    login user: users(:coordinator_manager)

    get :create_weaknesses_by_user, :params => {
      :weaknesses_by_user => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_audited.weaknesses_by_user.pdf_name'), 'weaknesses_by_user', 0
		)
  end
end
