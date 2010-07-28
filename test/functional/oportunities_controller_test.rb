require 'test_helper'

# Pruebas para el controlador de oportunidades
class OportunitiesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]

    private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list oportunities' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:oportunities)
    assert_select '#error_body', false
    assert_template 'oportunities/index'
  end

  test 'list oportunities with search and sort' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['description', 'review'],
      :order => 'review'
    }
    
    assert_response :success
    assert_not_nil assigns(:oportunities)
    assert_equal 2, assigns(:oportunities).size
    assert(assigns(:oportunities).all? do |o|
      o.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:oportunities).map {|o| o.review.identification}.sort,
      assigns(:oportunities).map {|o| o.review.identification}
    assert_select '#error_body', false
    assert_template 'oportunities/index'
  end

  test 'edit oportunity when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4 y 1o',
      :columns => ['description', 'review']
    }

    assert_redirected_to edit_oportunity_path(
      findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_oportunity))
    assert_not_nil assigns(:oportunities)
    assert_equal 1, assigns(:oportunities).size
  end

  test 'show oportunity' do
    perform_auth
    get :show, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_select '#error_body', false
    assert_template 'oportunities/show'
  end

  test 'new oportunity' do
    perform_auth
    get :new, :control_objective_item => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_select '#error_body', false
    assert_template 'oportunities/new'
  end

  test 'create oportunity' do
    counts_array = ['Oportunity.count', 'WorkPaper.count',
      'FindingRelation.count']

    perform_auth
    assert_difference counts_array do
      post :create, {
        :oportunity => {
          :control_objective_item_id => control_objective_items(
            :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
          :review_code => 'OM20',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :state => Finding::STATUS[:being_implemented],
          :user_ids => [users(:bare_user).id, users(:audited_user).id,
            users(:manager_user).id, users(:supervisor_user).id],
          :work_papers_attributes => {
            :new_1 => {
              :name => 'New workpaper name',
              :code => 'PTOM 20',
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

  test 'edit oportunity' do
    perform_auth
    get :edit, :id => findings(
      :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_select '#error_body', false
    assert_template 'oportunities/edit'
  end

  test 'update oportunity' do
    perform_auth
    assert_no_difference 'Oportunity.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        put :update, {
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id,
          :oportunity => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'OM20',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:confirmed],
            :solution_date => '',
            :user_ids => [users(:bare_user).id, users(:audited_user).id,
              users(:manager_user).id, users(:supervisor_user).id],
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTOM 20',
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

    assert_not_nil assigns(:oportunity)
    assert_redirected_to edit_oportunity_path(assigns(:oportunity))
    assert_equal 'OM20', assigns(:oportunity).review_code
  end

  test 'destroy oportunity' do
    perform_auth
    assert_difference 'Oportunity.count', -1 do
      delete :destroy, :id => findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_oportunity).id
    end

    assert_redirected_to oportunities_path
  end

  test 'follow up pdf' do
    perform_auth
    oportunity = Oportunity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_oportunity).id)

    assert_nothing_raised(Exception) do
      get :follow_up_pdf, :id => oportunity.id
    end

    assert_redirected_to oportunity.relative_follow_up_pdf_path
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'adm' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Sólo Admin (Admin second es de otra organización)
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'bare' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Solo Bare
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'x_nobody' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_user'
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_oportunity).id)

    perform_auth
    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'O01',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 3, assigns(:findings).size
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_finding_relation'

    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_notify_oportunity).id)

    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'O01',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).size # Se excluye la observación O01 que no tiene informe definitivo
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_finding_relation'

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
    assert_template 'oportunities/auto_complete_for_finding_relation'

    post :auto_complete_for_finding_relation, {
      :finding_relation_data => 'x_none',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 0, assigns(:findings).size # Sin resultados
    assert_select '#error_body', false
    assert_template 'oportunities/auto_complete_for_finding_relation'
  end
end