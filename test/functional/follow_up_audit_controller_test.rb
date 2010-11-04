require 'test_helper'

# Pruebas para el controlador de reportes de auditoría
class FollowUpAuditControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :weaknesses_by_state, :weaknesses_by_risk,
      :weaknesses_by_audit_type]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list reports' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_select '#error_body', false
    assert_template 'follow_up_audit/index'
  end

  test 'weaknesses by state report' do
    perform_auth

    get :weaknesses_by_state
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_state'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_state, :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    perform_auth
    post :create_weaknesses_by_state, :weaknesses_by_state => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
    },
    :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_state', 0)
  end

  test 'weaknesses by risk report' do
    perform_auth

    get :weaknesses_by_risk
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_risk'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_risk, :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_risk'
  end

  test 'create weaknesses by risk report' do
    perform_auth

    post :create_weaknesses_by_risk, :weaknesses_by_risk => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk', 0)
  end

  test 'weaknesses by audit type report' do
    perform_auth

    get :weaknesses_by_audit_type
    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_audit_type'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_audit_type, :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'follow_up_audit/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    perform_auth

    post :create_weaknesses_by_audit_type,
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end
end