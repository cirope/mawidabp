require 'test_helper'

# Pruebas para el controlador de reportes de conclusión
class ConclusionCommitteeReportsControllerTest < ActionController::TestCase
  fixtures :findings

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :synthesis_report, :high_risk_weaknesses_report,
      :fixed_weaknesses_report, :weaknesses_by_state, :weaknesses_by_risk,
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
    assert_template 'conclusion_committee_reports/index'
  end

  test 'synthesis report' do
    perform_auth

    get :synthesis_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/synthesis_report'

    assert_nothing_raised(Exception) do
      get :synthesis_report, :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/synthesis_report'
  end

  test 'filtered synthesis report' do
    perform_auth
    get :synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).size
    assert_template 'conclusion_committee_reports/synthesis_report'
  end

  test 'create synthesis report' do
    perform_auth

    get :create_synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'high risk weaknesses report' do
    perform_auth

    get :high_risk_weaknesses_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/high_risk_weaknesses_report'

    assert_nothing_raised(Exception) do
      get :high_risk_weaknesses_report, :high_risk_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/high_risk_weaknesses_report'
  end

  test 'create high risk weaknesses report' do
    perform_auth

    get :create_high_risk_weaknesses_report, :high_risk_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.high_risk_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'high_risk_weaknesses_report', 0)
  end

  test 'fixed weaknesses report' do
    perform_auth

    get :fixed_weaknesses_report
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/fixed_weaknesses_report'

    assert_nothing_raised(Exception) do
      get :fixed_weaknesses_report, :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/fixed_weaknesses_report'
  end

  test 'create fixed weaknesses report' do
    perform_auth

    get :create_fixed_weaknesses_report, :fixed_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'fixed_weaknesses_report', 0)
  end

  test 'weaknesses by state report' do
    perform_auth

    get :weaknesses_by_state
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_state'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_state, :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    perform_auth

    get :create_weaknesses_by_state, :weaknesses_by_state => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_state', 0)
  end

  test 'weaknesses by risk report' do
    perform_auth

    get :weaknesses_by_risk
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_risk'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_risk, :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end
    
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_risk'
  end

  test 'create weaknesses by risk report' do
    perform_auth

    post :create_weaknesses_by_risk, :weaknesses_by_risk => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_risk', 0)
  end

  test 'weaknesses by audit type report' do
    perform_auth

    get :weaknesses_by_audit_type
    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_audit_type'

    assert_nothing_raised(Exception) do
      get :weaknesses_by_audit_type, :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/weaknesses_by_audit_type'
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
      I18n.t(:'conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_audit_type', 0)
  end

  test 'cost analysis report' do
    perform_auth
    expected_title = I18n.t :'conclusion_committee_report.cost_analysis_title'

    get :cost_analysis
    assert_response :success
    assert_select '#error_body', false
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_committee_reports/cost_analysis'

    assert_nothing_raised(Exception) do
      get :cost_analysis, :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/cost_analysis'
  end

  test 'create cost analysis report' do
    perform_auth

    post :create_cost_analysis,
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end

  test 'detailed cost analysis report' do
    perform_auth
    expected_title = I18n.t :'conclusion_committee_report.detailed_cost_analysis_title'

    get :cost_analysis, :include_details => 1
    assert_response :success
    assert_select '#error_body', false
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_committee_reports/cost_analysis'

    assert_nothing_raised(Exception) do
      get :cost_analysis, :include_details => 1, :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'conclusion_committee_reports/cost_analysis'
  end

  test 'create detailed cost analysis report' do
    perform_auth

    post :create_cost_analysis, :include_details => 1,
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'conclusion_committee_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end
end