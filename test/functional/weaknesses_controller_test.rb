require 'test_helper'

# Pruebas para el controlador de debilidades
class WeaknessesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    id_param = {:id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:put, :update, id_param],
      [:put, :undo_reiteration, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
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

  test 'list weaknesses with search and sort' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['description', 'review'],
      :order => 'review'
    }
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_equal 2, assigns(:weaknesses).size
    assert(assigns(:weaknesses).all? do |w|
      w.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:weaknesses).map {|w| w.review.identification}.sort,
      assigns(:weaknesses).map {|w| w.review.identification}
    assert_select '#error_body', false
    assert_template 'weaknesses/index'
  end
  
  test 'list weaknesses for specific ids' do
    perform_auth
    ids = [
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
      findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id
    ]
    
    get :index, :ids => ids
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_equal 2, assigns(:weaknesses).size
    assert assigns(:weaknesses).all? { |w| ids.include?(w.id) }
    assert_select '#error_body', false
    assert_template 'weaknesses/index'
  end

  test 'edit weakness when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4 y 1w',
      :columns => ['description', 'review']
    }
    assert_redirected_to weakness_url(
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
          :review_code => 'O020',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :state => Finding::STATUS[:being_implemented],
          :origination_date => 1.day.ago.to_date.to_s(:db),
          :solution_date => '',
          :audit_recommendations => 'New proposed action',
          :effect => 'New effect',
          :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
          :priority => get_test_parameter(:admin_priorities).first[1],
          :follow_up_date => 2.days.from_now.to_date,
          :finding_user_assignments_attributes => {
            :new_1 => {
              :user_id => users(:bare_user).id, :process_owner => '0'
            },
            :new_2 => {
              :user_id => users(:audited_user).id, :process_owner => '1'
            },
            :new_3 => {
              :user_id => users(:auditor_user).id, :process_owner => '0'
            },
            :new_4 => {
              :user_id => users(:manager_user).id, :process_owner => '0'
            },
            :new_5 => {
              :user_id => users(:supervisor_user).id, :process_owner => '0'
            },
            :new_6 => {
              :user_id => users(:administrator_user).id, :process_owner => '0'
            }
          },
          :work_papers_attributes => {
            :new_1 => {
              :name => 'New workpaper name',
              :code => 'PTO 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:default_organization).id,
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
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_bare_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_bare_user).id,
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_audited_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_auditor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_manager_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_manager_user).id,
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_supervisor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_administrator_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_weakness_administrator_user).id,
                :user_id => users(:administrator_user).id,
                :process_owner => '0'
              }
            },
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTO 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(
                    TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            },
            :finding_relations_attributes => {
              :new_1 => {
                :description => 'Duplicated',
                :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
              }
            }
          }
        }
      end
    end

    assert_not_nil assigns(:weakness)
    assert_redirected_to edit_weakness_url(assigns(:weakness))
    assert_equal 'O020', assigns(:weakness).review_code
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
  
  test 'undo reiteration' do
    perform_auth
    weakness = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
    repeated_of_original_state = repeated_of.state
    
    assert !repeated_of.repeated?
    assert weakness.update_attributes(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert weakness.reload.repeated_of
    
    put :undo_reiteration, :id => weakness.to_param
    assert_redirected_to edit_weakness_url(weakness)
    
    assert !repeated_of.reload.repeated?
    assert_nil weakness.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :q => 'adm', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, users.size # Sólo Admin (Admin second es de otra organización)
    assert users.all? { |u| (u['label'] + u['informal']).match /adm/i }

    get :auto_complete_for_user, { :q => 'bare', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, users.size # Sólo Bare
    assert users.all? { |u| (u['label'] + u['informal']).match /bare/i }

    get :auto_complete_for_user, { :q => 'x_nobody', :format => :json }
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 0, users.size # Sin resultados
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)

    perform_auth
    get :auto_complete_for_finding_relation, {
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
      :q => 'x_none',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success
    
    findings = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 0, findings.size # Sin resultados
  end

  test 'auto complete for control objective item' do
    perform_auth
    get :auto_complete_for_control_objective_item, { :q => 'dependencia', :format => :json }
    assert_response :success
    
    cois = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, cois.size # Sólo bcra_A4609_security_management_responsible_dependency_item_editable porque no tiene informe definitivo
    assert cois.all? { |f| (f['label'] + f['informal']).match /dependencia/i }
    assert_equal(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item_editable).id,
      cois.first['id']
    )
    

    get :auto_complete_for_control_objective_item, { :q => '1 2 4', :format => :json }
    assert_response :success
    
    cois = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 2, cois.size # Todos los del informe 1 2 4
    assert cois.all? { |f| (f['label'] + f['informal']).match /1 2 4/i }

    get :auto_complete_for_control_objective_item, { :q => 'x_none', :format => :json }
    assert_response :success
    
    cois = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 0, cois.size # Sin resultados
  end
end