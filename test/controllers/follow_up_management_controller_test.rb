require 'test_helper'

# Pruebas para el controlador de reportes de la gerencia
class FollowUpManagementControllerTest < ActionController::TestCase
  fixtures :findings

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :weaknesses_by_state, :weaknesses_by_risk,
      :weaknesses_by_audit_type]

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
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'follow_up_management/index'
  end

  test 'weaknesses by state report' do
    login

    get :weaknesses_by_state
    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_state'

    assert_nothing_raised do
      get :weaknesses_by_state, :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
    end

    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    login
    post :create_weaknesses_by_state, :weaknesses_by_state => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
    },
    :report_title => 'New title',
    :controller_name => 'follow_up',
    :final => false

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_state', 0)
  end

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk
    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_risk'

    assert_nothing_raised do
      get :weaknesses_by_risk, :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
    end

    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_risk'
  end

  test 'create weaknesses by risk report' do
    login

    post :create_weaknesses_by_risk, :weaknesses_by_risk => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk', 0)
  end

  test 'weaknesses by audit type report' do
    login

    get :weaknesses_by_audit_type
    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_audit_type'

    assert_nothing_raised do
      get :weaknesses_by_audit_type, :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
    end

    assert_response :success
    assert_template 'follow_up_management/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    login

    post :create_weaknesses_by_audit_type,
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :report_title => 'New title',
        :controller_name => 'follow_up',
        :final => false

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end

  test 'control objective stats report' do
    login

    get :control_objective_stats
    assert_response :success
    assert_template 'follow_up_management/control_objective_stats'

    assert_nothing_raised do
      get :control_objective_stats, :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
    end

    assert_response :success
    assert_template 'follow_up_management/control_objective_stats'
  end

  test 'filtered control objective stats report' do
    login

    get :control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :control_objective => 'a'
      },
      :controller_name => 'follow_up',
      :final => false

    assert_response :success
    assert_template 'follow_up_management/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats', 0)
  end

  test 'process control stats report' do
    login

    get :process_control_stats
    assert_response :success
    assert_template 'follow_up_management/process_control_stats'

    assert_nothing_raised do
      get :process_control_stats, :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
    end

    assert_response :success
    assert_template 'follow_up_management/process_control_stats'
  end

  test 'filtered process control stats report' do
    login

    get :process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      },
      :controller_name => 'follow_up',
      :final => false

    assert_response :success
    assert_template 'follow_up_management/process_control_stats'
  end

  test 'create process control stats report' do
    login

    get :create_process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end
end
