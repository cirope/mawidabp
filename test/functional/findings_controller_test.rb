# encoding: utf-8
require 'test_helper'

# Pruebas para el controlador de observaciones y oportunidades
class FindingsControllerTest < ActionController::TestCase
  fixtures :findings, :users

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      :completed => 'complete',
      :id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).to_param
    }
    public_actions = []
    private_actions = [
      [:get, :index, {:completed => 'incomplete'}],
      [:get, :show, id_param],
      [:get, :edit, id_param],
      [:put, :update, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list findings' do
    perform_auth
    get :index, :completed => 'incomplete'
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings in xml' do
    perform_auth
    get :index, :completed => 'incomplete', :format => :xml
    assert_response :success
    assert_not_nil assigns(:findings)
    assert @response.headers['Content-Type'].start_with?('application/xml')
  end

  test 'list findings in csv' do
    perform_auth
    findings = Finding.limit 3

    assert_nothing_raised(Exception) do
      get :export_to_csv, :completed => 'incomplete', :findings => findings.to_a, :format => :csv
    end
  end

  test 'list findings for follow_up_committee' do
    perform_auth users(:committee_user)
    get :index, :completed => 'incomplete'
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings with search and sort' do
    perform_auth
    get :index, :completed => 'incomplete', :search => {
      :query => '1 2 4 y w',
      :columns => ['description', 'review'],
      :order => 'review'
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size
    assert assigns(:findings).all? {|f| f.review.identification.match(/1 2 4/i)}
    assert_equal assigns(:findings).map {|f| f.review.identification}.sort,
      assigns(:findings).map {|f| f.review.identification}
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings with search by date and sort' do
    perform_auth
    get :index, :completed => 'incomplete', :search => {
      :query => "> #{I18n.l(4.days.ago.to_date, :format => :minimal)}",
      :columns => ['review', 'issue_date']
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 5, assigns(:findings).size
    assert assigns(:findings).all? {|f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date}
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings for user' do
    perform_auth
    user = User.find(users(:first_time_user).id)
    get :index, :completed => 'incomplete', :user_id => user.id
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings for responsible auditor' do
    perform_auth
    user = User.find(users(:first_time_user).id)
    get :index, :completed => 'incomplete', :user_id => user.id, :as_responsible => true
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).size
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'list findings for specific ids' do
    perform_auth
    ids = [
      findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id,
      findings(:iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
    ]

    get :index, :completed => 'incomplete', :ids => ids
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
    assert_select '#error_body', false
    assert_template 'findings/index'
  end

  test 'edit finding when search match only one result' do
    perform_auth
    get :index, :completed => 'incomplete', :search => {
      :query => '1 2 4 y 1w',
      :columns => ['description', 'review']
    }

    assert_redirected_to finding_url('incomplete',
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness))
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).size
  end

  test 'show finding' do
    perform_auth
    get :show, :completed => 'incomplete',
      :id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/show'
  end

  test 'show finding for follow_up_committee' do
    perform_auth users(:committee_user)
    get :show, :completed => 'incomplete', :id => findings(
      :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_oportunity).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/show'
  end

  test 'edit finding' do
    perform_auth
    get :edit, :completed => 'incomplete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/edit'

    auditor_response = @response.body.dup

    perform_auth users(:audited_user)
    get :edit, :completed => 'incomplete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/edit'
    # Diferentes forms
    assert_not_equal auditor_response, @response.body
  end

  test 'unauthorized edit finding' do
    perform_auth users(:audited_second_user)
    get :edit, :completed => 'complete',
      :id => findings(:iso_27000_security_policy_3_1_item_weakness).id
    # No está autorizado el usuario a ver la observación
    assert_redirected_to findings_url('complete')
  end

  test 'unauthorized edit incomplete finding' do
    perform_auth users(:audited_user)
    get :edit, :completed => 'incomplete',
      :id => findings(:iso_27000_security_organization_4_2_item_editable_weakness_incomplete).id

    # No está autorizado el usuario a ver la observación por estar incompleta
    assert_redirected_to findings_url('incomplete')
  end

  test 'update finding' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    difference_counts = ['WorkPaper.count', 'FindingAnswer.count', 'Cost.count',
      'ActionMailer::Base.deliveries.size', 'FindingRelation.count']

    assert_no_difference 'Finding.count' do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          put :update, {
            :completed => 'incomplete',
            :id => findings(
              :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
            :finding => {
              :control_objective_item_id => control_objective_items(
                :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
              :review_code => 'O020',
              :description => 'Updated description',
              :answer => 'Updated answer',
              :audit_comments => 'Updated audit comments',
              :state => Finding::STATUS[:unconfirmed],
              :origination_date => 1.day.ago.to_date.to_s(:db),
              :solution_date => '',
              :audit_recommendations => 'Updated proposed action',
              :effect => 'Updated effect',
              :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
              :priority => get_test_parameter(:admin_priorities).first[1],
              :follow_up_date => '',
              :finding_user_assignments_attributes => {
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id,
                  :user_id => users(:bare_user).id,
                  :process_owner => '0'
                },
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id,
                  :user_id => users(:audited_user).id,
                  :process_owner => '1'
                },
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id,
                  :user_id => users(:auditor_user).id,
                  :process_owner => '0'
                },
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id,
                  :user_id => users(:manager_user).id,
                  :process_owner => '0'
                },
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id,
                  :user_id => users(:supervisor_user).id,
                  :process_owner => '0'
                },
                finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id => {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id,
                  :user_id => users(:administrator_user).id,
                  :process_owner => '0'
                }
              },
              :work_papers_attributes => {
                :new_1 => {
                  :name => 'New workpaper name',
                  :code => 'PTSO 20',
                  :number_of_pages => '10',
                  :description => 'New workpaper description',
                  :file_model_attributes => {
                    :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                      'text/plain')
                  }
                }
              },
              :finding_answers_attributes => {
                :new_1 => {
                  :answer => 'New answer',
                  :auditor_comments => 'New auditor comments',
                  :user_id => users(:administrator_user).id,
                  :notify_users => '1',
                  :file_model_attributes => {
                    :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                      'text/plain')
                  }
                }
              },
              :finding_relations_attributes => {
                :new_1 => {
                  :description => 'Duplicated',
                  :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
                }
              },
              :costs_attributes => {
                :new_1 => {
                  :cost => '12.5',
                  :cost_type => 'audit',
                  :description => 'New cost description',
                  :user_id => users(:administrator_user).id
                }
              }
            }
          }
        end
      end
    end

    assert_redirected_to edit_finding_url('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_equal 'Updated description', assigns(:finding).description
  end

  test 'update finding with audited user' do
    perform_auth users(:audited_user)
    no_difference_count = ['Finding.count', 'WorkPaper.count',
      'FindingRelation.count']
    difference_count = ['FindingAnswer.count', 'Cost.count', 'FileModel.count']

    assert_no_difference no_difference_count do
      assert_difference difference_count do
        put :update, {
          :completed => 'incomplete',
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
          :finding => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
            :review_code => 'O020',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :origination_date => 35.day.ago.to_date.to_s(:db),
            :solution_date => 31.days.from_now.to_date,
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
            :priority => get_test_parameter(:admin_priorities).first[1],
            :follow_up_date => 3.days.from_now.to_date,
            :finding_user_assignments_attributes => {
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id => {
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id => {
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id => {
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id => {
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id => {
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id => {
                :user_id => users(:administrator_user).id,
                :process_owner => '0'
              }
            },
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTSO 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                    'text/plain')
                }
              }
            },
            :finding_answers_attributes => {
              :new_1 => {
                :answer => 'New answer',
                :auditor_comments => 'New audited comments',
                :commitment_date => I18n.l(Date.tomorrow),
                :user_id => users(:audited_user).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                    'text/plain')
                }
              }
            },
            :finding_relations_attributes => {
              :new_1 => {
                :description => 'Duplicated',
                :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
              }
            },
            :costs_attributes => {
              :new_1 => {
                :cost => '12.5',
                :cost_type => 'audit',
                :description => 'New cost description',
                :user_id => users(:administrator_user).id
              }
            }
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_not_equal 'Updated description', assigns(:finding).description
  end

  test 'update finding and notify to the new user' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'Finding.count' do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        put :update, {
          :completed => 'incomplete',
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
          :finding => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'O020',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :solution_date => '',
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
            :priority => get_test_parameter(:admin_priorities).first[1],
            :follow_up_date => '',
            :users_for_notification => [users(:bare_user).id],
            :finding_user_assignments_attributes => {
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id,
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id,
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id,
                :user_id => users(:administrator_user).id,
                :process_owner => '0'
              }
            }
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_equal 'Updated description', assigns(:finding).description
  end

  test 'export list to pdf' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :completed => 'incomplete'
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('finding.pdf.pdf_name'), Finding.table_name)
  end

  test 'export detailed list to pdf' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :completed => 'incomplete', :include_details => 1
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('finding.pdf.pdf_name'), Finding.table_name)
  end

  test 'export list with search' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :completed => 'incomplete', :search => {
      :query => '1 2 4 y w',
      :columns => ['description', 'review'],
      :order => 'review'
    }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('finding.pdf.pdf_name'), Finding.table_name)
  end

  test 'export detailed list with search' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :completed => 'incomplete', :include_details => 1,
        :search => {
          :query => '1 2 4 y w',
          :columns => ['description', 'review'],
          :order => 'review'
        }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('finding.pdf.pdf_name'), Finding.table_name)
  end

  test 'follow up pdf' do
    perform_auth
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    assert_nothing_raised(Exception) do
      get :follow_up_pdf, :completed => 'incomplete', :id => finding.id
    end

    assert_redirected_to finding.relative_follow_up_pdf_path
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :completed => 'incomplete', :q => 'adm', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Sólo Admin (Admin second es de otra organización)
    assert users.all? { |u| (u['label'] + u['informal']).match /adm/i }

    get :auto_complete_for_user, { :completed => 'incomplete', :q => 'bare', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Sólo Bare
    assert users.all? { |u| (u['label'] + u['informal']).match /bare/i }

    get :auto_complete_for_user, { :completed => 'incomplete', :q => 'x_nobody', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size # Sin resultados
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)

    perform_auth
    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'O001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, findings.size
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)

    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'O001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'O001, 1 2 3',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }

    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'x_none',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, findings.size # Sin resultados
  end
end
