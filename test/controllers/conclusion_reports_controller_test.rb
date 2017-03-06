require 'test_helper'

# Pruebas para el controlador de reportes de auditoría
class ConclusionReportsControllerTest < ActionController::TestCase
  fixtures :findings

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :synthesis_report, :weaknesses_by_state, :weaknesses_by_risk,
      :weaknesses_by_audit_type, :weaknesses_by_audit_type, :cost_analysis,
      :cost_summary, :weaknesses_by_risk_report, :fixed_weaknesses_report
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
    assert_template 'conclusion_reports/index'
  end

  test 'synthesis report' do
    login

    get :synthesis_report, :controller_name => 'conclusion'
    assert_response :success
    assert_template 'conclusion_reports/synthesis_report'

    assert_nothing_raised do
      get :synthesis_report, :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
    end

    assert_response :success
    assert_template 'conclusion_reports/synthesis_report'
  end

  test 'filtered synthesis report' do
    login
    get :synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      },
      :controller_name => 'conclusion'

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_template 'conclusion_reports/synthesis_report'
  end

  test 'create synthesis report' do
    login

    post :create_synthesis_report, :synthesis_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'weaknesses by state report' do
    login

    get :weaknesses_by_state
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_state'

    assert_nothing_raised do
      get :weaknesses_by_state, :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    login

    post :create_weaknesses_by_state, :weaknesses_by_state => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_state', 0)
  end

  test 'weaknesses by risk' do
    login

    get :weaknesses_by_risk
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk'

    assert_nothing_raised do
      get :weaknesses_by_risk, :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk'
  end

  test 'create weaknesses by risk' do
    login

    post :create_weaknesses_by_risk, :weaknesses_by_risk => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk', 0)
  end

  test 'weaknesses by audit type report' do
    login

    get :weaknesses_by_audit_type
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_audit_type'

    assert_nothing_raised do
      get :weaknesses_by_audit_type, :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    login

    post :create_weaknesses_by_audit_type,
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end

  test 'cost analysis report' do
    login
    expected_title = I18n.t 'conclusion_report.cost_analysis_title'

    get :cost_analysis
    assert_response :success
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_reports/cost_analysis'

    assert_nothing_raised do
      get :cost_analysis, :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_analysis'
  end

  test 'create cost analysis report' do
    login

    post :create_cost_analysis,
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end

  test 'detailed cost analysis report' do
    login
    expected_title = I18n.t 'conclusion_report.detailed_cost_analysis_title'

    get :cost_analysis, :include_details => 1
    assert_response :success
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_reports/cost_analysis'

    assert_nothing_raised do
      get :cost_analysis, :include_details => 1, :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_analysis'
  end

  test 'create detailed cost analysis report' do
    login

    post :create_cost_analysis, :include_details => 1,
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end

  test 'cost summary report' do
    login
    expected_title = I18n.t 'conclusion_report.cost_summary_title'

    get :cost_summary
    assert_response :success
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_reports/cost_summary'

    assert_nothing_raised do
      get :cost_summary, :cost_summary => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_summary'
  end

  test 'create cost summary report' do
    login

    post :create_cost_summary,
      :cost_summary => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_summary.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_summary', 0)
  end

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'

    assert_nothing_raised do
      get :weaknesses_by_risk_report, :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'
  end

  test 'filtered weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report, :weaknesses_by_risk_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'
  end

  test 'create weaknesses by risk report' do
    login

    get :create_weaknesses_by_risk_report, :weaknesses_by_risk_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_report', 0)
  end

  test 'fixed weaknesses report' do
    login

    get :fixed_weaknesses_report
    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'

    assert_nothing_raised do
      get :fixed_weaknesses_report, :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'
  end

  test 'filtered fixed weaknesses report' do
    login

    get :fixed_weaknesses_report, :fixed_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'
  end

  test 'create fixed weaknesses report' do
    login

    get :create_fixed_weaknesses_report, :fixed_weaknesses_report => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'fixed_weaknesses_report', 0)
  end

  test 'control objective stats report' do
    login

    get :control_objective_stats
    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats'

    assert_nothing_raised do
      get :control_objective_stats, :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats'
  end

  test 'filtered control objective stats report' do
    login

    get :control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :control_objective => 'a',
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats', 0)
  end

  test 'control objective stats by review report' do
    login

    get :control_objective_stats_by_review
    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats_by_review'

    assert_nothing_raised do
      get :control_objective_stats_by_review, :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats_by_review'
  end

  test 'filtered control objective stats by review report' do
    login

    get :control_objective_stats_by_review, :control_objective_stats_by_review => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :control_objective => 'a',
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats_by_review'
  end

  test 'create control objective stats by review report' do
    login

    get :create_control_objective_stats_by_review, :control_objective_stats_by_review => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_stats_by_review.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats_by_review', 0)
  end

  test 'process control stats report' do
    login

    get :process_control_stats
    assert_response :success
    assert_template 'conclusion_reports/process_control_stats'

    assert_nothing_raised do
      get :process_control_stats, :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/process_control_stats'
  end

  test 'filtered process control stats report' do
    login

    get :process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :best_practice => 'a',
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :process_control => 'seg'
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/process_control_stats'
  end

  test 'create process control stats report' do
    login

    get :create_process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end

  test 'weaknesses graphs for user' do
    login

    get :weaknesses_graphs, :weaknesses_graphs => {
      :user_id => users(:administrator_user).id
    },
    :final => true

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'weaknesses graphs for business unit' do
    login

    get :weaknesses_graphs, :weaknesses_graphs => {
      :business_unit_id => business_units(:business_unit_one).id
    },
    :final => true

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'weaknesses graphs for process control' do
    login

    get :weaknesses_graphs, :weaknesses_graphs => {
      :process_control_id => process_controls(:iso_27000_security_policy).id
    },
    :final => true

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'benefits report' do
    login

    get :benefits
    assert_response :success
    assert_template 'conclusion_reports/benefits'

    assert_nothing_raised do
      get :benefits, :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_reports/benefits'
  end

  test 'filtered benefits report' do
    login

    get :benefits, :benefits => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one',
      :control_objective => 'a',
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_reports/benefits'
  end

  test 'create benefits report' do
    login

    get :create_benefits, :benefits => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.benefits.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'benefits', 0)
  end
end
