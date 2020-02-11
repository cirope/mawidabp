require 'test_helper'

# Pruebas para el controlador de reportes de auditoría
class FollowUpAuditControllerTest < ActionController::TestCase

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      :index, :synthesis_report, :qa_indicators, :weaknesses_by_state,
      :weaknesses_by_risk, :weaknesses_by_audit_type,
      :weaknesses_by_risk_report, :fixed_weaknesses_report,
      :weaknesses_by_month, :weaknesses_current_situation,
      :weaknesses_by_control_objective, :weaknesses_evolution,
      :weaknesses_list, :weaknesses_brief, :weaknesses_by_risk_and_business_unit
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
    assert_template 'follow_up_audit/index'
  end

  test 'synthesis report' do
    login

    get :synthesis_report, :params => { :controller_name => 'follow_up' }
    assert_response :success
    assert_template 'follow_up_audit/synthesis_report'

    assert_nothing_raised do
      get :synthesis_report, :params => {
        :synthesis_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up'
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/synthesis_report'
  end

  test 'filtered synthesis report' do
    login
    get :synthesis_report, :params => {
      :synthesis_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :scope => 'committee'
      },
      :controller_name => 'follow_up'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 3, assigns(:filters).count
    assert_template 'follow_up_audit/synthesis_report'
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
      :controller_name => 'follow_up'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.synthesis_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'synthesis_report', 0)
  end

  test 'review stats report' do
    login

    get :review_stats_report, :params => { :controller_name => 'follow_up' }
    assert_response :success
    assert_template 'follow_up_audit/review_stats_report'

    assert_nothing_raised do
      get :review_stats_report, :params => {
        :review_stats_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up'
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/review_stats_report'
  end

  test 'filtered review stats report' do
    login
    get :review_stats_report, :params => {
      :review_stats_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three'
      },
      :controller_name => 'follow_up'
    }

    assert_response :success
    assert_not_nil assigns(:filters)
    assert_equal 2, assigns(:filters).count
    assert_template 'follow_up_audit/review_stats_report'
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
      :controller_name => 'follow_up'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.review_stats_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'review_stats_report', 0)
  end

  test 'qa indicators' do
    login

    get :qa_indicators
    assert_response :success
    assert_template 'follow_up_audit/qa_indicators'

    assert_nothing_raised do
      get :qa_indicators, :params => {
        :qa_indicators => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/qa_indicators'
  end

  test 'create qa indicators' do
    login

    post :create_qa_indicators, :params => {
      :qa_indicators => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.qa_indicators.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'qa_indicators', 0)
  end

  test 'weaknesses by state report' do
    login

    get :weaknesses_by_state
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_state'

    assert_nothing_raised do
      get :weaknesses_by_state, :params => {
        :weaknesses_by_state => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_state'
  end

  test 'create weaknesses by state report' do
    login
    post :create_weaknesses_by_state, :params => {
      :weaknesses_by_state => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_state.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_state', 0)
  end

  test 'weaknesses by risk' do
    login

    get :weaknesses_by_risk
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk'

    assert_nothing_raised do
      get :weaknesses_by_risk, :params => {
        :weaknesses_by_risk => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :compliance => 'yes',
          :repeated => 'false'
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk'
  end

  test 'create weaknesses by risk' do
    login

    post :create_weaknesses_by_risk, :params => {
      :weaknesses_by_risk => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk', 0)
  end

  test 'weaknesses by risk and business unit report' do
    login

    get :weaknesses_by_risk_and_business_unit
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_and_business_unit'

    assert_nothing_raised do
      get :weaknesses_by_risk_and_business_unit, :params => {
        :weaknesses_by_risk_and_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :mid_date => Time.zone.today
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_and_business_unit'
  end

  test 'weaknesses by risk and business unit report filtered by icon' do
    login

    assert_nothing_raised do
      get :weaknesses_by_risk_and_business_unit, :params => {
        :weaknesses_by_risk_and_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :mid_date => Time.zone.today,
          :icon => 'tag'
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_and_business_unit'
  end

  test 'create weaknesses by risk and business unit report' do
    login

    post :create_weaknesses_by_risk_and_business_unit, :params => {
      :weaknesses_by_risk_and_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :mid_date => Time.zone.today
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_risk_and_business_unit.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_and_business_unit', 0)
  end

  test 'create weaknesses by risk and business unit report filtered by icon' do
    login

    post :create_weaknesses_by_risk_and_business_unit, :params => {
      :weaknesses_by_risk_and_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :mid_date => Time.zone.today,
        :icon => 'tag'
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_risk_and_business_unit.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_and_business_unit', 0)
  end

  test 'weaknesses by audit type report' do
    login

    get :weaknesses_by_audit_type
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_audit_type'

    assert_nothing_raised do
      get :weaknesses_by_audit_type, :params => {
        :weaknesses_by_audit_type => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_audit_type'
  end

  test 'create weaknesses by audit type report' do
    login

    post :create_weaknesses_by_audit_type, :params => {
      :weaknesses_by_audit_type => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end

  test 'units analysis report' do
    login

    get :follow_up_cost_analysis
    assert_response :success
    assert_template 'follow_up_audit/follow_up_cost_analysis'

    assert_nothing_raised do
      get :follow_up_cost_analysis, :params => {
        :follow_up_cost_analysis => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/follow_up_cost_analysis'
  end

  test 'create units analysis report' do
    login

    post :create_follow_up_cost_analysis, :params => {
      :follow_up_cost_analysis => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title'
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.follow_up_cost_analysis.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'follow_up_cost_analysis', 0)
  end

  test 'weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'

    assert_nothing_raised do
      get :weaknesses_by_risk_report, :params => {
        :weaknesses_by_risk_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'
  end

  test 'filtered weaknesses by risk report' do
    login

    get :weaknesses_by_risk_report, :params => {
      :weaknesses_by_risk_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_risk_report'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_risk_report', 0)
  end

  test 'weaknesses by month' do
    login

    get :weaknesses_by_month
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'

    assert_nothing_raised do
      get :weaknesses_by_month, :params => {
        :weaknesses_by_month => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'
  end

  test 'filtered weaknesses by month' do
    login

    get :weaknesses_by_month, :params => {
      :weaknesses_by_month => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :risk => '1',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_month'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_month.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_month', 0)
  end

  test 'weaknesses current situation' do
    login

    get :weaknesses_current_situation
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_current_situation'

    assert_nothing_raised do
      get :weaknesses_current_situation, :params => {
        :weaknesses_current_situation => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_current_situation'
  end

  test 'weaknesses current situation from permalink' do
    login

    get :weaknesses_current_situation, :params => {
      permalink_token: permalinks(:link).token
    }
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_current_situation'
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
        :controller_name => 'follow_up',
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
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :control_objective_tags => ['one'],
        :weakness_tags => ['two'],
        :review_tags => ['three'],
        :compliance => 'no'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_current_situation'
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
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no',
        :impact => [WEAKNESS_IMPACT.keys.first],
        :operational_risk => [WEAKNESS_OPERATIONAL_RISK.keys.first],
        :internal_control_components => [WEAKNESS_INTERNAL_CONTROL_COMPONENTS.first]
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_current_situation'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_current_situation.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_current_situation', 0)
  end

  test 'create weaknesses current situation permalink' do
    login

    assert_difference 'Permalink.count' do
      post :create_weaknesses_current_situation_permalink, :params => {
        :weaknesses_current_situation_permalink => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }, xhr: true, as: :js
    end

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end

  test 'weaknesses by control objective' do
    login

    get :weaknesses_by_control_objective
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_control_objective'

    assert_nothing_raised do
      get :weaknesses_by_control_objective, :params => {
        :weaknesses_by_control_objective => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_control_objective'
  end

  test 'weaknesses by control objective as CSV' do
    login

    get :weaknesses_by_control_objective, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_by_control_objective, :params => {
        :weaknesses_by_control_objective => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses by control objective' do
    login

    get :weaknesses_by_control_objective, :params => {
      :weaknesses_by_control_objective => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_control_objective'
  end

  test 'filtered weaknesses by control objective by extra attributes' do
    skip unless POSTGRESQL_ADAPTER

    login

    get :weaknesses_by_control_objective, :params => {
      :weaknesses_by_control_objective => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no',
        :impact => [WEAKNESS_IMPACT.keys.first],
        :operational_risk => [WEAKNESS_OPERATIONAL_RISK.keys.first],
        :internal_control_components => [WEAKNESS_INTERNAL_CONTROL_COMPONENTS.first]
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_control_objective'
  end

  test 'create weaknesses by control objective' do
    login

    get :create_weaknesses_by_control_objective, :params => {
      :weaknesses_by_control_objective => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_control_objective.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_control_objective', 0)
  end

  test 'weaknesses by business unit' do
    login

    get :weaknesses_by_business_unit
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_business_unit'

    assert_nothing_raised do
      get :weaknesses_by_business_unit, :params => {
        :weaknesses_by_business_unit => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_business_unit'
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
        :controller_name => 'follow_up',
        :final => false
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
        :controller_name => 'follow_up',
        :final => false
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
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :business_unit_id => [business_units(:business_unit_one).id].to_json
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_business_unit'
  end

  test 'create weaknesses by business_unit' do
    login

    get :create_weaknesses_by_business_unit, :params => {
      :weaknesses_by_business_unit => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_business_unit.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_business_unit', 0)
  end

  test 'weaknesses by user' do
    login

    get :weaknesses_by_user
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_user'

    assert_nothing_raised do
      get :weaknesses_by_user, :params => {
        :weaknesses_by_user => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_user'
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
        :controller_name => 'follow_up',
        :final => false
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_by_user'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_by_user.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_by_user', 0)
  end

  test 'weaknesses evolution' do
    login

    get :weaknesses_evolution
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_evolution'

    assert_nothing_raised do
      get :weaknesses_evolution, :params => {
        :weaknesses_evolution => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_evolution'
  end

  test 'weaknesses evolution as CSV' do
    login

    get :weaknesses_evolution, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_evolution, :params => {
        :weaknesses_evolution => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses evolution' do
    login

    get :weaknesses_evolution, :params => {
      :weaknesses_evolution => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_status_was => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :control_objective_tags => ['one'],
        :weakness_tags => ['two'],
        :review_tags => ['three'],
        :compliance => 'no'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_evolution'
  end

  test 'filtered weaknesses evolution by extra attributes' do
    skip unless POSTGRESQL_ADAPTER

    login

    get :weaknesses_evolution, :params => {
      :weaknesses_evolution => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_status_was => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no',
        :impact => [WEAKNESS_IMPACT.keys.first],
        :operational_risk => [WEAKNESS_OPERATIONAL_RISK.keys.first],
        :internal_control_components => [WEAKNESS_INTERNAL_CONTROL_COMPONENTS.first]
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_evolution'
  end

  test 'create weaknesses evolution' do
    login

    get :create_weaknesses_evolution, :params => {
      :weaknesses_evolution => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_evolution.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_evolution', 0)
  end

  test 'weaknesses list' do
    login

    get :weaknesses_list
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_list'

    assert_nothing_raised do
      get :weaknesses_list, :params => {
        :weaknesses_list => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_list'
  end

  test 'weaknesses list as CSV' do
    login

    get :weaknesses_list, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_list, :params => {
        :weaknesses_list => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'filtered weaknesses list' do
    login

    get :weaknesses_list, :params => {
      :weaknesses_list => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :control_objective_tags => ['one'],
        :weakness_tags => ['two'],
        :review_tags => ['three'],
        :compliance => 'no'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_list'
  end

  test 'filtered weaknesses list by extra attributes' do
    skip unless POSTGRESQL_ADAPTER

    login

    get :weaknesses_list, :params => {
      :weaknesses_list => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :risk => ['', '1', '2'],
        :finding_status => ['', Finding::STATUS[:being_implemented]],
        :finding_title => 'a',
        :business_unit_type => ['', business_unit_types(:cycle).id],
        :compliance => 'no',
        :impact => [WEAKNESS_IMPACT.keys.first],
        :operational_risk => [WEAKNESS_OPERATIONAL_RISK.keys.first],
        :internal_control_components => [WEAKNESS_INTERNAL_CONTROL_COMPONENTS.first]
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_list'
  end

  test 'weaknesses brief' do
    login

    get :weaknesses_brief
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_brief'

    assert_nothing_raised do
      get :weaknesses_brief, :params => {
        :weaknesses_brief => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_brief'
  end

  test 'filtered weaknesses brief' do
    login

    get :weaknesses_brief
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_brief'

    assert_nothing_raised do
      get :weaknesses_brief, :params => {
        :weaknesses_brief => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date,
          :cut_date => 10.days.ago.to_date,
          :user_id => users(:audited).id,
          :order_by => 'risk'
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_brief'
  end

  test 'weaknesses brief as CSV' do
    login

    get :weaknesses_brief, as: :csv
    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type

    assert_nothing_raised do
      get :weaknesses_brief, :params => {
        :weaknesses_brief => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }, as: :csv
    end

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'create weaknesses brief' do
    login

    get :create_weaknesses_brief, :params => {
      :weaknesses_brief => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.weaknesses_brief.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'weaknesses_brief', 0)
  end

  test 'fixed weaknesses report' do
    login

    get :fixed_weaknesses_report
    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'

    assert_nothing_raised do
      get :fixed_weaknesses_report, :params => {
        :fixed_weaknesses_report => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'
  end

  test 'filtered fixed weaknesses report' do
    login

    get :fixed_weaknesses_report, :params => {
      :fixed_weaknesses_report => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'three',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/fixed_weaknesses_report'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'fixed_weaknesses_report', 0)
  end

  test 'control objective stats report' do
    login

    get :control_objective_stats
    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'

    assert_nothing_raised do
      get :control_objective_stats, :params => {
        :control_objective_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'
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
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats'
  end

  test 'create control objective stats report' do
    login

    get :create_control_objective_stats, :params => {
      :control_objective_stats => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.control_objective_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats', 0)
  end

  test 'control objective stats by review report' do
    login

    get :control_objective_stats_by_review
    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'

    assert_nothing_raised do
      get :control_objective_stats_by_review, :params => {
        :control_objective_stats_by_review => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => true
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'
  end

  test 'filtered control objective stats by review report' do
    login

    get :control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
      },
      :controller_name => 'follow_up',
      :final => true
    }

    assert_response :success
    assert_template 'follow_up_audit/control_objective_stats_by_review'
  end

  test 'create control objective stats by review report' do
    login

    get :create_control_objective_stats_by_review, :params => {
      :control_objective_stats_by_review => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => true
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.control_objective_stats_by_review.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'control_objective_stats_by_review', 0)
  end

  test 'process control stats report' do
    login

    get :process_control_stats
    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'

    assert_nothing_raised do
      get :process_control_stats, :params => {
        :process_control_stats => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'
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
        :process_control => 'seg',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/process_control_stats'
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
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.process_control_stats.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'process_control_stats', 0)
  end

  test 'weaknesses graphs for user' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :user_id => users(:administrator).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses graphs for business unit' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :business_unit_id => business_units(:business_unit_one).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses graphs for process control' do
    login

    get :weaknesses_graphs, :params => {
      :weaknesses_graphs => {
        :process_control_id => process_controls(:security_policy).id
      },
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_graphs'
  end

  test 'weaknesses report' do
    login

    get :weaknesses_report
    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'

    assert_nothing_raised do
      get :weaknesses_report, :params => {
        :weaknesses_report => {
          :review                    => '1',
          :project                   => '2',
          :process_control           => '3',
          :control_objective         => '4',
          :tags                      => '5',
          :user_id                   => users(:administrator).id.to_s,
          :finding_status            => '1',
          :finding_title             => '1',
          :risk                      => '1',
          :priority                  => Finding.priorities_values.first,
          :compliance                => 'yes',
          :repeated                  => 'false',
          :issue_date                => Date.today.to_s(:db),
          :issue_date_operator       => '=',
          :origination_date          => Date.today.to_s(:db),
          :origination_date_operator => '>',
          :follow_up_date            => Date.today.to_s(:db),
          :follow_up_date_until      => Date.today.to_s(:db),
          :follow_up_date_operator   => 'between',
          :solution_date             => Date.today.to_s(:db),
          :solution_date_operator    => '='
        }
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'
  end

  test 'filtered weaknesses report' do
    login

    get :weaknesses_report, :params => {
      :weaknesses_report => {
        :finding_status => Finding::STATUS[:being_implemented].to_s,
        :finding_title  => 'a'
      }
    }

    assert_response :success
    assert_template 'follow_up_audit/weaknesses_report'
  end

  test 'create weaknesses report' do
    login

    post :create_weaknesses_report, :params => {
      :weaknesses_report => {
        :finding_status => Finding::STATUS[:being_implemented].to_s
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle'
    }

    assert_response :redirect
  end

  test 'weaknesses report as CSV' do
    login

    get :weaknesses_report, :params => {
      :weaknesses_report => {
        :finding_status => Finding::STATUS[:being_implemented].to_s
      }
    }, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'benefits report' do
    login

    get :benefits
    assert_response :success
    assert_template 'follow_up_audit/benefits'

    assert_nothing_raised do
      get :benefits, :params => {
        :benefits => {
          :from_date => 10.years.ago.to_date,
          :to_date => 10.years.from_now.to_date
        },
        :controller_name => 'follow_up',
        :final => false
      }
    end

    assert_response :success
    assert_template 'follow_up_audit/benefits'
  end

  test 'filtered benefits report' do
    login

    get :benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
        :business_unit_type => business_unit_types(:cycle).id,
        :business_unit => 'one',
        :control_objective => 'a',
        :finding_status => Finding::STATUS[:being_implemented],
        :finding_title => 'a'
      },
      :controller_name => 'follow_up',
      :final => false
    }

    assert_response :success
    assert_template 'follow_up_audit/benefits'
  end

  test 'create benefits report' do
    login

    get :create_benefits, :params => {
      :benefits => {
        :from_date => 10.years.ago.to_date,
        :to_date => 10.years.from_now.to_date,
      },
      :report_title => 'New title',
      :report_subtitle => 'New subtitle',
      :controller_name => 'follow_up',
      :final => false
    }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('follow_up_committee_report.benefits.pdf_name',
        :from_date => 10.years.ago.to_date.to_formatted_s(:db),
        :to_date => 10.years.from_now.to_date.to_formatted_s(:db)),
      'benefits', 0)
  end

  test 'findings tagged report' do
    login

    get :tagged_findings_report
    assert_response :success
    assert_template 'follow_up_audit/tagged_findings_report'

    assert_nothing_raised do
      get :tagged_findings_report, params: {
        tagged_findings_report: {
          tags_count: 3
        }
      }
    end

    assert_template 'follow_up_audit/tagged_findings_report'

    assert_nothing_raised do
      get :tagged_findings_report, params: {
        tagged_findings_report: {
          tags_count: 3,
          finding_status: [Finding::STATUS[:being_implemented]]
        }
      }
    end

    assert_template 'follow_up_audit/tagged_findings_report'
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
end
