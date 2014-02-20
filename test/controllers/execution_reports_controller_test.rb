require 'test_helper'

# Pruebas para el controlador de reportes de ejecución
class ExecutionReportsControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :weaknesses_by_state_execution, :detailed_management_report
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
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'execution_reports/index'
  end

  test 'detailed management report' do
    perform_auth

    get :detailed_management_report
    assert_response :success
    assert_template 'execution_reports/detailed_management_report'

    assert_nothing_raised do
      get :detailed_management_report, detailed_management_report: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_template 'execution_reports/detailed_management_report'
  end

  test 'create detailed management report' do
    perform_auth

    post :create_detailed_management_report, detailed_management_report: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.detailed_management_report.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)
  end

  test 'weaknesses by state execution report' do
    perform_auth

    get :weaknesses_by_state_execution
    assert_response :success
    assert_template 'execution_reports/weaknesses_by_state_execution'

    assert_nothing_raised do
      get :weaknesses_by_state_execution, weaknesses_by_state_execution: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_template 'execution_reports/weaknesses_by_state_execution'
  end

  test 'create weaknesses by state execution report' do
    perform_auth
    post :create_weaknesses_by_state_execution, weaknesses_by_state_execution: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date
    },
    report_title: 'New title'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)
  end
end
