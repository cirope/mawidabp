require 'test_helper'

# Pruebas para el controlador de observaciones y oportunidades
class FindingsControllerTest < ActionController::TestCase
  fixtures :findings, :users

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :edit, :update, :destroy]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:alert]
    end

    public_actions.each do |action|
      get action
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

  test 'edit finding when search match only one result' do
    perform_auth
    get :index, :completed => 'incomplete', :search => {
      :query => '1 2 4 y 1w',
      :columns => ['description', 'review']
    }
    
    assert_redirected_to edit_finding_path('incomplete',
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness))
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).size
  end

  test 'show finding' do
    perform_auth
    get :show, :completed => 'complete',
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
    get :edit, :completed => 'complete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/edit'

    auditor_response = response_from_page_or_rjs

    perform_auth users(:audited_user)
    get :edit, :completed => 'complete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_select '#error_body', false
    assert_template 'findings/edit'
    # Diferentes forms
    assert_not_equal auditor_response, response_from_page_or_rjs
  end

  test 'unauthorized edit finding' do
    perform_auth users(:supervisor_second_user)
    get :edit, :completed => 'complete',
      :id => findings(:iso_27000_security_policy_3_1_item_weakness).id
    # No está autorizado el usuario a ver la observación
    assert_redirected_to findings_path('complete')
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
                :bcra_A4609_data_proccessing_impact_analisys_item).id,
              :review_code => 'O20',
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
              :user_ids => findings(
                :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).user_ids,
              :work_papers_attributes => {
                :new_1 => {
                  :name => 'New workpaper name',
                  :code => 'PTSO 20',
                  :number_of_pages => '10',
                  :description => 'New workpaper description',
                  :organization_id => organizations(:default_organization).id,
                  :file_model_attributes => {
                    :uploaded_data => ActionController::TestUploadedFile.new(
                      TEST_FILE, 'text/plain')
                  }
                }
              },
              :finding_answers_attributes => {
                :new_1 => {
                  :answer => 'New answer',
                  :auditor_comments => 'New auditor comments',
                  :answer_type => get_test_parameter(:admin_finding_answers_types).first[1],
                  :user_id => users(:administrator_user).id,
                  :notify_users => '1',
                  :file_model_attributes => {
                    :uploaded_data => ActionController::TestUploadedFile.new(
                      TEST_FILE, 'text/plain')
                  }
                }
              },
              :finding_relations_attributes => {
                :new_1 => {
                  :finding_relation_type => FindingRelation::TYPES[:duplicated],
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
    
    assert_redirected_to edit_finding_path('incomplete', assigns(:finding))
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
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'O20',
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
            :user_ids => [users(:administrator_user).id, users(:bare_user).id,
              users(:audited_user).id, users(:manager_user).id,
              users(:supervisor_user).id],
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTSO 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :uploaded_data => ActionController::TestUploadedFile.new(
                    TEST_FILE, 'text/plain')
                }
              }
            },
            :finding_answers_attributes => {
              :new_1 => {
                :answer => 'New answer',
                :auditor_comments => 'New audited comments',
                :answer_type => get_test_parameter(:admin_finding_answers_types).first[1],
                :user_id => users(:audited_user).id,
                :file_model_attributes => {
                  :uploaded_data => ActionController::TestUploadedFile.new(
                    TEST_FILE, 'text/plain')
                }
              }
            },
            :finding_relations_attributes => {
              :new_1 => {
                :finding_relation_type => FindingRelation::TYPES[:duplicated],
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

    assert_redirected_to edit_finding_path('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_not_equal 'Updated description', assigns(:finding).description
  end

  test 'update finding and notify to the new user' do
    perform_auth

    user_ids = findings(
      :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).user_ids
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
            :review_code => 'O20',
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
            :user_ids => user_ids,
            :users_for_notification => [user_ids.first]
          }
        }
      end
    end

    assert_redirected_to edit_finding_path('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_equal 'Updated description', assigns(:finding).description
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
    post :auto_complete_for_user, { :completed => 'incomplete',
      :user_data => 'adm' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Sólo Admin (Admin second es de otra organización)
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_user'

    post :auto_complete_for_user, { :completed => 'incomplete',
      :user_data => 'bare' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Solo Bare
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_user'

    post :auto_complete_for_user, { :completed => 'incomplete',
      :user_data => 'x_nobody' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_user'
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_editable_being_implemented_oportunity).id)

    perform_auth
    post :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :finding_relation_data => 'O01',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 3, assigns(:findings).size
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_finding_relation'

    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)

    post :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :finding_relation_data => 'O01',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size # Se excluye la observación O01 que no tiene informe definitivo
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :finding_relation_data => 'O01, 1 2 3',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).size # Solo O01 del informe 1 2 3
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :finding_relation_data => 'x_none',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 0, assigns(:findings).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'findings/auto_complete_for_finding_relation'
  end
end