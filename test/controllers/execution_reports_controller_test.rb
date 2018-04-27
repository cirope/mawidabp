require 'test_helper'

# Pruebas para el controlador de reportes de ejecución
class ExecutionReportsControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :weaknesses_by_state_execution, :detailed_management_report,
      :planned_cost_summary
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
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'execution_reports/index'
  end

  test 'detailed management report' do
    login

    get :detailed_management_report
    assert_response :success
    assert_template 'execution_reports/detailed_management_report'

    assert_nothing_raised do
      get :detailed_management_report, params: {
        detailed_management_report: {
          from_date: 10.years.ago.to_date,
          to_date: 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'execution_reports/detailed_management_report'
  end

  test 'create detailed management report' do
    login

    post :create_detailed_management_report, params: {
      detailed_management_report: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.detailed_management_report.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)
  end

  test 'weaknesses by state execution report' do
    login

    get :weaknesses_by_state_execution
    assert_response :success
    assert_template 'execution_reports/weaknesses_by_state_execution'

    assert_nothing_raised do
      get :weaknesses_by_state_execution, params: {
        weaknesses_by_state_execution: {
          from_date: 10.years.ago.to_date,
          to_date: 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'execution_reports/weaknesses_by_state_execution'
  end

  test 'create weaknesses by state execution report' do
    login

    post :create_weaknesses_by_state_execution, params: {
      weaknesses_by_state_execution: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date
      },
      report_title: 'New title'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)
  end

  test 'weaknesses report' do
    login

    get :weaknesses_report, params: { execution: 'true' }
    assert_response :success
    assert_template 'execution_reports/weaknesses_report'

    assert_nothing_raised do
      get :weaknesses_report, params: {
        execution: 'true',
        weaknesses_report: {
          review: '1',
          project: '2',
          process_control: '3',
          control_objective: '4',
          tags: '5',
          user_id: users(:administrator).id.to_s,
          finding_status: '1',
          finding_title: '1',
          risk: '1',
          compliance: 'yes',
          repeated: 'false',
          priority: Finding.priorities_values.first,
          issue_date: Date.today.to_s(:db),
          issue_date_operator: '=',
          origination_date: Date.today.to_s(:db),
          origination_date_operator: '>',
          follow_up_date: Date.today.to_s(:db),
          follow_up_date_until: Date.today.to_s(:db),
          follow_up_date_operator: 'between',
          solution_date: Date.today.to_s(:db),
          solution_date_operator: '='
        }
      }
    end

    assert_response :success
    assert_template 'execution_reports/weaknesses_report'
  end

  test 'filtered weaknesses report' do
    login

    get :weaknesses_report, params: {
      execution: 'true',
      weaknesses_report: {
        finding_status: Finding::STATUS[:being_implemented].to_s,
        finding_title: 'a'
      }
    }

    assert_response :success
    assert_template 'execution_reports/weaknesses_report'
  end

  test 'create weaknesses report' do
    login

    post :create_weaknesses_report, params: {
      execution: 'true',
      weaknesses_report: {
        finding_status: Finding::STATUS[:being_implemented].to_s
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_response :redirect
  end

  test 'reviews with incomplete work papers' do
    login

    get :reviews_with_incomplete_work_papers_report
    assert_response :success
    assert_template 'execution_reports/reviews_with_incomplete_work_papers_report'
  end

  test 'reviews with revised work papers' do
    login

    get :reviews_with_incomplete_work_papers_report, params: { revised: true }
    assert_response :success
    assert_template 'execution_reports/reviews_with_incomplete_work_papers_report'
  end

  test 'planned cost summary report' do
    login

    get :planned_cost_summary
    assert_response :success
    assert_template 'execution_reports/planned_cost_summary'

    assert_nothing_raised do
      get :planned_cost_summary, params: {
        planned_cost_summary: {
          from_date: 10.years.ago.to_date,
          to_date: 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'execution_reports/planned_cost_summary'
  end

  test 'create planned cost summary report' do
    login

    post :create_planned_cost_summary, params: {
      planned_cost_summary: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date
      },
      report_title: 'New title'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.planned_cost_summary.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'planned_cost_summary', 0)
  end
end
