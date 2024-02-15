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
      :cost_summary, :weaknesses_by_risk_report, :fixed_weaknesses_report,
      :weaknesses_by_month
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

    get :synthesis_report, :params => { :controller_name => 'conclusion' }
    assert_response :success
    assert_template 'conclusion_reports/synthesis_report'

    assert_nothing_raised do
      get :synthesis_report, :params => {
        :synthesis_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/synthesis_report'
  end

  test 'filtered synthesis report' do
    login
    get :synthesis_report, :params => {
      :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :scope => 'committee'
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 3, assigns(:filters).count
    assert_template 'conclusion_reports/synthesis_report'
  end

  test 'create synthesis report' do
    login

    post :create_synthesis_report, :params => {
      :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'review stats report' do
    login

    get :review_stats_report, :params => { :controller_name => 'conclusion' }
    assert_response :success
    assert_template 'conclusion_reports/review_stats_report'

    assert_nothing_raised do
      get :review_stats_report, :params => {
        :review_stats_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/review_stats_report'
  end

  test 'filtered review stats report' do
    login
    get :review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one'
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_equal 2, assigns(:conclusion_reviews).count
    assert_template 'conclusion_reports/review_stats_report'
  end

  test 'filtered review stats report for scored reports' do
    reviews(:past_review).update_column :score_type, 'none'

    login

    get :review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one'
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_equal 1, assigns(:conclusion_reviews).count
    assert_template 'conclusion_reports/review_stats_report'
  end

  test 'create review stats report' do
    login

    post :create_review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.review_stats_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'review_stats_report', 0)
  end

  test 'review scores report' do
    login

    get :review_scores_report, :params => { :controller_name => 'conclusion' }
    assert_response :success
    assert_template 'conclusion_reports/review_scores_report'

    assert_nothing_raised do
      get :review_scores_report, :params => {
        :review_scores_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/review_scores_report'
  end

  test 'filtered review scores report' do
    login
    get :review_scores_report, :params => {
      :review_scores_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one'
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_template 'conclusion_reports/review_scores_report'
  end

  test 'create review scores report' do
    login

    post :create_review_scores_report, :params => {
      :review_scores_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.review_scores_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'review_scores_report', 0)
  end

  test 'review score details report' do
    login

    get :review_score_details_report, :params => { :controller_name => 'conclusion' }
    assert_response :success
    assert_template 'conclusion_reports/review_score_details_report'

    assert_nothing_raised do
      get :review_score_details_report, :params => {
        :review_score_details_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/review_score_details_report'
  end

  test 'review score details report as CSV' do
    login

    get :review_score_details_report, :params => { :controller_name => 'conclusion' }, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :review_score_details_report, :params => {
        :review_score_details_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion', as: :csv
      }
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered review score details report' do
    login
    get :review_score_details_report, :params => {
      :review_score_details_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :conclusion => [CONCLUSION_OPTIONS.first],
        :scope => ['committee'],
        :business_unit_type => [business_unit_types(:cycle).id],
        :business_unit => 'one, two'
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 4, assigns(:filters).count
    assert_template 'conclusion_reports/review_score_details_report'
  end

  test 'create review score details report' do
    login

    post :create_review_score_details_report, :params => {
      :review_score_details_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.review_score_details_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'review_score_details_report', 0)
  end

  test 'weaknesses by state report' do
    login

    get :weaknesses_by_state
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_state'

    assert_nothing_raised do
      get :weaknesses_by_state, :params => {
        :weaknesses_by_state => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    login

    post :create_weaknesses_by_state, :params => {
      :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :weaknesses_by_risk, :params => {
        :weaknesses_by_risk => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :compliance => 'yes',
          :repeated => 'false'
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk'
  end

  test 'create weaknesses by risk' do
    login

    post :create_weaknesses_by_risk, :params => {
      :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :weaknesses_by_audit_type, :params => {
        :weaknesses_by_audit_type => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :controller_name => 'conclusion',
          :final => true
        }
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    login

    post :create_weaknesses_by_audit_type, :params => {
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :cost_analysis, :params => {
        :cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_analysis'
  end

  test 'create cost analysis report' do
    login

    post :create_cost_analysis, :params => {
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end

  test 'cost analysis report as CSV' do
    login

    get :cost_analysis, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :cost_analysis, :params => {
        :cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'detailed cost analysis report' do
    login
    expected_title = I18n.t 'conclusion_report.detailed_cost_analysis_title'

    get :cost_analysis, :params => { :include_details => 1 }
    assert_response :success
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_reports/cost_analysis'

    assert_nothing_raised do
      get :cost_analysis, :params => {
        :include_details => 1,
        :cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_analysis'
  end

  test 'create detailed cost analysis report' do
    login

    post :create_cost_analysis, :params => {
      :include_details => 1,
      :cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_analysis', 0)
  end

  test 'detailed cost analysis report as CSV' do
    login

    get :cost_analysis, :params => { :include_details => 1 }, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :cost_analysis, :params => {
        :include_details => 1,
        :cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'cost summary report' do
    login
    expected_title = I18n.t 'conclusion_report.cost_summary_title'

    get :cost_summary
    assert_response :success
    assert_equal assigns(:title), expected_title
    assert_template 'conclusion_reports/cost_summary'

    assert_nothing_raised do
      get :cost_summary, :params => {
        :cost_summary => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/cost_summary'
  end

  test 'create cost summary report' do
    login

    post :create_cost_summary, :params => {
      :cost_summary => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_report.cost_summary.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'cost_summary', 0)
  end

  test 'cost summary report as CSV' do
    login

    get :cost_summary, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :cost_summary, :params => {
        :cost_summary => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'

    assert_nothing_raised do
      get :weaknesses_by_risk_report, :params => {
        :weaknesses_by_risk_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'
  end

  test 'filtered weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report, :params => {
      :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one'
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_risk_report'
  end

  test 'create weaknesses by risk report' do
    login

    get :create_weaknesses_by_risk_report, :params => {
      :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_report', 0)
  end

  test 'weaknesses by business unit' do
    login

    get :weaknesses_by_business_unit
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_business_unit'

    assert_nothing_raised do
      get :weaknesses_by_business_unit, :params => {
        :weaknesses_by_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_business_unit'
  end

  test 'weaknesses by business unit as CSV' do
    login

    get :weaknesses_by_business_unit, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_by_business_unit, :params => {
        :weaknesses_by_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'weaknesses by business unit as RTF' do
    login

    get :weaknesses_by_business_unit, as: :rtf
    assert_response :success
    assert_match Mime[:rtf].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_by_business_unit, :params => {
        :weaknesses_by_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }, as: :rtf
    end

    assert_response :success
    assert_match Mime[:rtf].to_s, @response.content_type
  end

  test 'filtered weaknesses by business unit' do
    login

    get :weaknesses_by_business_unit, :params => {
      :weaknesses_by_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :business_unit_id => [business_units(:business_unit_one).id].to_json
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_business_unit'
  end

  test 'create weaknesses by business unit' do
    login

    get :create_weaknesses_by_business_unit, :params => {
      :weaknesses_by_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_business_unit.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_business_unit', 0)
  end

  test 'weaknesses by user' do
    login

    get :weaknesses_by_user
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_user'

    assert_nothing_raised do
      get :weaknesses_by_user, :params => {
        :weaknesses_by_user => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_user'
  end

  test 'weaknesses by user as CSV' do
    login

    get :weaknesses_by_user, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_by_user, :params => {
        :weaknesses_by_user => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses by user' do
    login

    get :weaknesses_by_user, :params => {
      :weaknesses_by_user => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :user_id => [users(:audited).id.to_s]
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_user'
  end

  test 'create weaknesses by user' do
    login

    get :create_weaknesses_by_user, :params => {
      :weaknesses_by_user => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_user.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_user', 0)
  end

  test 'weaknesses by month' do
    login

    get :weaknesses_by_month
    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_month'

    assert_nothing_raised do
      get :weaknesses_by_month, :params => {
        :weaknesses_by_month => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => false
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_month'
  end

  test 'filtered weaknesses by month' do
    login

    get :weaknesses_by_month, :params => {
      :weaknesses_by_month => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'conclusion',
      :final => false
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_by_month'
  end

  test 'create weaknesses by month' do
    login

    get :create_weaknesses_by_month, :params => {
      :weaknesses_by_month => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => false
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.weaknesses_by_month.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_month', 0)
  end

  test 'fixed weaknesses report' do
    login

    get :fixed_weaknesses_report
    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'

    assert_nothing_raised do
      get :fixed_weaknesses_report, :params => {
        :fixed_weaknesses_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'
  end

  test 'filtered fixed weaknesses report' do
    login

    get :fixed_weaknesses_report, :params => {
      :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one'
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/fixed_weaknesses_report'
  end

  test 'create fixed weaknesses report' do
    login

    get :create_fixed_weaknesses_report, :params => {
      :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :control_objective_stats, :params => {
        :control_objective_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats'
  end

  test 'filtered control objective stats report' do
    login

    get :control_objective_stats, :params => {
      :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :params => {
      :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :control_objective_stats_by_review, :params => {
        :control_objective_stats_by_review => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats_by_review'
  end

  test 'filtered control objective stats by review report' do
    login

    get :control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a'
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/control_objective_stats_by_review'
  end

  test 'create control objective stats by review report' do
    login

    get :create_control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
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
      get :process_control_stats, :params => {
        :process_control_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/process_control_stats'
  end

  test 'filtered process control stats report' do
    login

    get :process_control_stats, :params => {
      :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :best_practice => 'a',
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :process_control => 'seg'
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/process_control_stats'
  end

  test 'create process control stats report' do
    login

    get :create_process_control_stats, :params => {
      :process_control_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end

  test 'process control stats report as CSV' do
    login

    assert_nothing_raised do
      get :process_control_stats_csv, format: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'weaknesses graphs for user' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :user_id => users(:administrator).id
      },
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'weaknesses graphs for business unit' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :business_unit_id => business_units(:business_unit_one).id
      },
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'weaknesses graphs for process control' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :process_control_id => process_controls(:security_policy).id
      },
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/weaknesses_graphs'
  end

  test 'benefits report' do
    login

    get :benefits
    assert_response :success
    assert_template 'conclusion_reports/benefits'

    assert_nothing_raised do
      get :benefits, :params => {
        :benefits => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion',
        :final => true
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/benefits'
  end

  test 'filtered benefits report' do
    login

    get :benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a'
      },
      :controller_name => 'conclusion',
      :final => true
    }

    assert_response :success
    assert_template 'conclusion_reports/benefits'
  end

  test 'create benefits report' do
    login

    get :create_benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion',
      :final => true
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.benefits.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'benefits', 0)
  end

  test 'control objective counts' do
    login

    get :control_objective_counts
    assert_response :success
    assert_template 'conclusion_reports/control_objective_counts'

    assert_nothing_raised do
      get :control_objective_counts, :params => {
        :control_objective_counts => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }
    end

    assert_response :success
    assert_template 'conclusion_reports/control_objective_counts'
  end

  test 'control objective counts as CSV' do
    login

    get :control_objective_counts, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :control_objective_counts, :params => {
        :control_objective_counts => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'conclusion'
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered control objective counts' do
    login

    get :control_objective_counts, :params => {
      :control_objective_counts => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => ['', business_unit_types(:cycle).id]
      },
      :controller_name => 'conclusion'
    }

    assert_response :success
    assert_template 'conclusion_reports/control_objective_counts'
  end

  test 'create control objective counts' do
    login

    get :create_control_objective_counts, :params => {
      :control_objective_counts => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'conclusion'
    }

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.control_objective_counts.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_counts', 0)
  end

  test 'nbc annual report report' do
    skip unless Current.conclusion_pdf_format == 'nbc'

    set_organization
    login

    get :nbc_annual_report
    assert_response :success
    assert_template 'conclusion_reports/nbc_annual_report'
  end

  test 'create nbc annual report report' do
    skip unless Current.conclusion_pdf_format == 'nbc'

    set_organization
    login

    assert_nothing_raised do
      post :create_nbc_annual_report, params: {
        nbc_annual_report: {
          period_id: periods(:current_period).id,
          date: Date.today.to_s,
          cc: 'cc',
          name: 'name',
          objective: 'objective',
          conclusion: 'conclusion',
          introduction_and_scope: 'introduction and scope'
        }
      }
    end

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.nbc_annual_report.pdf_name',
        from_date: period.start,
        to_date: period.end),
        'nbc_annual_report',
        0)
  end

  test 'nbc internal control qualification as group of companies' do
    skip unless Current.conclusion_pdf_format == 'nbc'

    set_organization
    login

    get :nbc_internal_control_qualification_as_group_of_companies
    assert_response :success
    assert_template 'conclusion_reports/nbc_internal_control_qualification_as_group_of_companies'
  end

  test 'create nbc internal control qualification as group of companies' do
    skip unless Current.conclusion_pdf_format == 'nbc'

    set_organization
    login

    other_organization = organizations(:google)

    BusinessUnitType.create([
      { name: "Cycle", business_unit_label: 'C', organization: other_organization },
      { name: "Consolidated Substantive", business_unit_label: 'CS', organization: other_organization }
    ])

    business_unit_types = [
      business_unit_types(:bcra).name,
      business_unit_types(:consolidated_substantive).name,
      business_unit_types(:cycle).name
    ]

    assert_nothing_raised do
      post :create_nbc_internal_control_qualification_as_group_of_companies, params: {
        nbc_internal_control_qualification_as_group_of_companies: {
          period_id: periods(:current_period).id,
          date: Date.today,
          cc: 'cc',
          name: 'name',
          objective: 'objective',
          conclusion: 'conclusion',
          introduction_and_scope: 'introduction and scope',
          previous_period_id: periods(:past_period).id,
          business_unit_types: business_unit_types
        }
      }
    end

    Current.organization = organizations(:cirope)
    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_committee_report.nbc_internal_control_qualification_as_group_of_companies_report.pdf_name',
        from_date: period.start,
        to_date: period.end),
        'nbc_internal_control_qualification_as_group_of_companies_report',
        0)
  end
end
