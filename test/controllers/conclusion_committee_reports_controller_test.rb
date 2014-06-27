require 'test_helper'

# Pruebas para el controlador de reportes de conclusión
class ConclusionCommitteeReportsControllerTest < ActionController::TestCase
  fixtures :findings

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :synthesis_report, :weaknesses_by_risk_report,
      :fixed_weaknesses_report]

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
    assert_template 'conclusion_committee_reports/index'
  end

  test 'synthesis report' do
    login

    get :synthesis_report, :controller_name => 'conclusion'
    assert_response :success
    assert_template 'conclusion_committee_reports/synthesis_report'

    assert_nothing_raised do
      get :synthesis_report, :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
    end

    assert_response :success
    assert_template 'conclusion_committee_reports/synthesis_report'
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
    assert_template 'conclusion_committee_reports/synthesis_report'
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

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report
    assert_response :success
    assert_template 'conclusion_committee_reports/weaknesses_by_risk_report'

    assert_nothing_raised do
      get :weaknesses_by_risk_report, :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_committee_reports/weaknesses_by_risk_report'
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
    assert_template 'conclusion_committee_reports/weaknesses_by_risk_report'
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
    assert_template 'conclusion_committee_reports/fixed_weaknesses_report'

    assert_nothing_raised do
      get :fixed_weaknesses_report, :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_committee_reports/fixed_weaknesses_report'
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
    assert_template 'conclusion_committee_reports/fixed_weaknesses_report'
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
    assert_template 'conclusion_committee_reports/control_objective_stats'

    assert_nothing_raised do
      get :control_objective_stats, :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_committee_reports/control_objective_stats'
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
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_committee_reports/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :control_objective_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date
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

  test 'process control stats report' do
    login

    get :process_control_stats
    assert_response :success
    assert_template 'conclusion_committee_reports/process_control_stats'

    assert_nothing_raised do
      get :process_control_stats, :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
    end

    assert_response :success
    assert_template 'conclusion_committee_reports/process_control_stats'
  end

  test 'filtered process control stats report' do
    login

    get :process_control_stats, :process_control_stats => {
      :from_date => 10.years.ago.to_date,
      :to_date => 10.years.from_now.to_date,
      :business_unit_type => business_unit_types(:cycle).id,
      :business_unit => 'one'
      },
      :controller_name => 'conclusion',
      :final => true

    assert_response :success
    assert_template 'conclusion_committee_reports/process_control_stats'
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
end
