require 'test_helper'

# Pruebas para el controlador de debilidades
class WeaknessesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list weaknesses' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_select '#error_body', false
    assert_template 'weaknesses/index'
  end

  test 'list weaknesses with search' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['description', 'review']
    }
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_equal 2, assigns(:weaknesses).size
    assert(assigns(:weaknesses).all? do |w|
      w.review.identification.match(/1 2 4/i)
    end)
    assert_select '#error_body', false
    assert_template 'weaknesses/index'
  end

  test 'edit weakness when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4 y 1w',
      :columns => ['description', 'review']
    }
    assert_redirected_to edit_weakness_path(
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness))
    assert_not_nil assigns(:weaknesses)
    assert_equal 1, assigns(:weaknesses).size
  end

  test 'show weakness' do
    perform_auth
    get :show, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_select '#error_body', false
    assert_template 'weaknesses/show'
  end

  test 'new weakness' do
    perform_auth
    get :new, :control_objective_item => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_select '#error_body', false
    assert_template 'weaknesses/new'
  end

  test 'create weakness' do
    counts_array = ['Weakness.count', 'WorkPaper.count',
      'FindingRelation.count']

    perform_auth
    assert_difference counts_array do
      post :create, {
        :weakness => {
          :control_objective_item_id => control_objective_items(
            :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
          :review_code => 'O20',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :state => Finding::STATUS[:being_implemented],
          :solution_date => '',
          :audit_recommendations => 'New proposed action',
          :effect => 'New effect',
          :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
          :priority => get_test_parameter(:admin_priorities).first[1],
          :follow_up_date => 2.days.from_now.to_date,
          :user_ids => [users(:administrator_user).id, users(:bare_user).id,
            users(:audited_user).id, users(:manager_user).id,
            users(:supervisor_user).id],
          :work_papers_attributes => {
            :new_1 => {
              :name => 'New workpaper name',
              :code => 'PTO 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:default_organization).id,
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
          }
        }
      }
    end
  end

  test 'edit weakness' do
    perform_auth
    get :edit, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_select '#error_body', false
    assert_template 'weaknesses/edit'
  end

  test 'update weakness' do
    perform_auth
    assert_no_difference 'Weakness.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        put :update, {
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_weakness).id,
          :weakness => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'O20',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :solution_date => '',
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
            :priority => get_test_parameter(:admin_priorities).first[1],
            :follow_up_date => '',
            :user_ids => [users(:administrator_user).id, users(:bare_user).id,
              users(:audited_user).id, users(:manager_user).id,
              users(:supervisor_user).id],
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTO 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:default_organization).id,
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
            }
          }
        }
      end
    end

    assert_not_nil assigns(:weakness)
    assert_redirected_to edit_weakness_path(assigns(:weakness))
    assert_equal 'O20', assigns(:weakness).review_code
  end

  test 'destroy weakness' do
    perform_auth
    assert_difference 'Weakness.count', -1 do
      delete :destroy, :id => findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id
    end

    assert_redirected_to weaknesses_path
  end

  test 'follow up pdf' do
    perform_auth
    weakness = Weakness.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    assert_nothing_raised(Exception) do
      get :follow_up_pdf, :id => weakness.id
    end

    assert_redirected_to weakness.relative_follow_up_pdf_path
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'adm' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Sólo Admin (Admin second es de otra organización)
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'bare' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Solo Bare
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'x_nobody' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_user'
  end

  test 'auto complete for finding relation' do
    perform_auth
    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'O01',
      :finding_id => findings(:bcra_A4609_security_management_responsible_dependency_editable_being_implemented_oportunity).id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 3, assigns(:findings).size
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'O01',
      :finding_id => findings(:iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size # Se excluye la observación O01 que no tiene informe definitivo
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :finding_relation_data => 'O01, 1 2 3',
      :finding_id => findings(:iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).size # Solo O01 del informe 1 2 3
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'x_none',
      :finding_id => findings(:iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 0, assigns(:findings).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'weaknesses/auto_complete_for_finding_relation'
  end
end