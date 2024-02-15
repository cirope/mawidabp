require 'test_helper'

# Pruebas para el controlador de reportes de ejecución
class ExecutionReportsControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :weaknesses_by_state_execution, :detailed_management_report,
      :planned_cost_summary, :weaknesses_current_situation
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

    Current.organization = organizations(:cirope)
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

    Current.organization = organizations(:cirope)
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
          issue_date: Date.today.to_fs(:db),
          issue_date_operator: '=',
          origination_date: Date.today.to_fs(:db),
          origination_date_operator: '>',
          follow_up_date: Date.today.to_fs(:db),
          follow_up_date_until: Date.today.to_fs(:db),
          follow_up_date_operator: 'between',
          solution_date: Date.today.to_fs(:db),
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

    assert_match I18n.t('execution_reports.weaknesses_report.pdf_name'),
      response.location
  end

  test 'queue async weaknesses report' do
    login

    old_count = ::SEND_REPORT_EMAIL_AFTER_COUNT
    back_url  = weaknesses_report_url execution: true

    silence_warnings { ::SEND_REPORT_EMAIL_AFTER_COUNT = 1 }

    request.headers['HTTP_REFERER'] = back_url

    post :create_weaknesses_report, params: {
      execution: 'true',
      weaknesses_report: {
        finding_status: Finding::STATUS[:being_implemented].to_s
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    silence_warnings { ::SEND_REPORT_EMAIL_AFTER_COUNT = old_count }

    assert_response :redirect
    assert_match back_url, response.location
  end

  test 'weaknesses report as CSV' do
    login

    get :weaknesses_report, params: {
      execution: 'true',
      weaknesses_report: {
        finding_status: Finding::STATUS[:being_implemented].to_s
      }
    }, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
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

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_reports.planned_cost_summary.pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)),
      'planned_cost_summary', 0)
  end

  test 'findings tagged report' do
    login

    get :tagged_findings_report
    assert_response :success
    assert_template 'execution_reports/tagged_findings_report'

    assert_nothing_raised do
      get :tagged_findings_report, params: {
        tagged_findings_report: {
          tags_count: 3
        }
      }
    end

    assert_template 'execution_reports/tagged_findings_report'

    assert_nothing_raised do
      get :tagged_findings_report, params: {
        tagged_findings_report: {
          tags_count: 3,
          finding_status: [Finding::STATUS[:being_implemented]]
        }
      }
    end

    assert_template 'execution_reports/tagged_findings_report'
  end

  test 'findings tagged report csv' do
    login

    assert_nothing_raised do
      get :tagged_findings_report, params: {
        tagged_findings_report: {
          tags_count: 3,
          finding_status: [Finding::STATUS[:being_implemented]]
        }
      },
      as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end


  test 'create findings tagged report' do
    login

    post :create_tagged_findings_report, params: {
      tagged_findings_report: {
        tags_count: 3
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_response :redirect

    post :create_tagged_findings_report, params: {
      tagged_findings_report: {
        tags_count: 3,
        finding_status: [Finding::STATUS[:being_implemented]]
      },
      report_title: 'New title',
      report_subtitle: 'New subtitle'
    }

    assert_response :redirect
  end

  test 'weaknesses current situation' do
    login

    get :weaknesses_current_situation
    assert_response :success
    assert_template 'execution_reports/weaknesses_current_situation'

    assert_nothing_raised do
      get :weaknesses_current_situation, :params => {
        :weaknesses_current_situation => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'execution',
        :final => false
      }
    end

    assert_response :success
    assert_template 'execution_reports/weaknesses_current_situation'
  end

  test 'weaknesses current situation from permalink' do
    login

    get :weaknesses_current_situation, :params => {
      permalink_token: permalinks(:execution_link).token
    }
    assert_response :success
    assert_template 'execution_reports/weaknesses_current_situation'
  end

  test 'weaknesses current situation as CSV' do
    login

    get :weaknesses_current_situation, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_current_situation, :params => {
        :weaknesses_current_situation => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'execution',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses current situation' do
    login

    get :weaknesses_current_situation, :params => {
      :weaknesses_current_situation => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :cut_date => 10.days.ago.to_date,
        :review => '1',
        :project => '2',
        :risk => ['', '1', '2'],
        :priority => Finding.priorities_values.last.to_s,
        :scope => ['committee'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :control_objective_tags => ['one'],
        :weakness_tags => ['two'],
        :review_tags => ['three'],
        :compliance => 'no'
      },
      :controller_name => 'execution',
      :final => false
    }

    assert_response :success
    assert_template 'execution_reports/weaknesses_current_situation'
  end

  test 'filtered weaknesses current situation by extra attributes' do
    skip unless POSTGRESQL_ADAPTER

    login

    get :weaknesses_current_situation, :params => {
      :weaknesses_current_situation => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :cut_date => 10.days.ago.to_date,
        :risk => ['', '1', '2'],
        :priority => Finding.priorities_values.last.to_s,
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no',
        :impact => [WEAKNESS_IMPACT.keys.first],
        :operational_risk => [WEAKNESS_OPERATIONAL_RISK.keys.first],
        :internal_control_components => [WEAKNESS_INTERNAL_CONTROL_COMPONENTS.first]
      },
      :controller_name => 'execution',
      :final => false
    }

    assert_response :success
    assert_template 'execution_reports/weaknesses_current_situation'
  end

  test 'create weaknesses current situation' do
    login

    post :create_weaknesses_current_situation, :params => {
      :weaknesses_current_situation => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :cut_date => 10.days.ago.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'execution',
      :final => false
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('execution_committee_report.weaknesses_current_situation.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_current_situation', 0)
  end

  test 'create weaknesses current situation permalink' do
    login

    assert_difference 'Permalink.count' do
      post :create_weaknesses_current_situation_permalink, :params => {
        :weaknesses_current_situation => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'execution',
        :final => false
      }, xhr: true, as: :js
    end

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end
end
