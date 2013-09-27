require 'test_helper'

class PotentialNonconformitiesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param]
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

  test 'list potential_nonconformities' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:potential_nonconformities)
    assert_select '#error_body', false
    assert_template 'potential_nonconformities/index'
  end

  test 'list potential_nonconformities with search and sort' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['description', 'review'],
      :order => 'review'
    }

    assert_response :success
    assert_not_nil assigns(:potential_nonconformities)
    assert_equal 2, assigns(:potential_nonconformities).size
    assert(assigns(:potential_nonconformities).all? do |o|
      o.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:potential_nonconformities).map {|o| o.review.identification}.sort,
      assigns(:potential_nonconformities).map {|o| o.review.identification}
    assert_select '#error_body', false
    assert_template 'potential_nonconformities/index'
  end

  test 'edit potential_nonconformity when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4 y 1ncp',
      :columns => ['description', 'review']
    }

    assert_redirected_to potential_nonconformity_url(
      findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_potential_nonconformity))
    assert_not_nil assigns(:potential_nonconformities)
    assert_equal 1, assigns(:potential_nonconformities).size
  end

  test 'show potential_nonconformity' do
    perform_auth
    get :show, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity).id
    assert_response :success
    assert_not_nil assigns(:potential_nonconformity)
    assert_select '#error_body', false
    assert_template 'potential_nonconformities/show'
  end

  test 'new potential_nonconformity' do
    perform_auth
    get :new, :control_objective_item => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:potential_nonconformity)
    assert_select '#error_body', false
    assert_template 'potential_nonconformities/new'
  end

  test 'create potential_nonconformity' do
    counts_array = ['PotentialNonconformity.count', 'WorkPaper.count',
      'FindingRelation.count']

    perform_auth
    assert_difference counts_array do
      post :create, {
        :potential_nonconformity => {
          :control_objective_item_id => control_objective_items(
            :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
          :review_code => 'NCP020',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :origination_date => 1.day.ago.to_date.to_s(:db),
          :state => Finding::STATUS[:being_implemented],
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
              :code => 'PTNCP 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {:file => Rack::Test::UploadedFile.new(
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

  test 'edit potential_nonconformity' do
    perform_auth
    get :edit, :id => findings(
      :bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity).id
    assert_response :success
    assert_not_nil assigns(:potential_nonconformity)
    assert_select '#error_body', false
    assert_template 'potential_nonconformities/edit'
  end

  test 'update potential nonconformity' do
    perform_auth
    assert_no_difference 'PotentialNonconformity.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        patch :update, {
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity).id,
          :potential_nonconformity => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'NCP020',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:confirmed],
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :solution_date => '',
            :finding_user_assignments_attributes => {
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_audited_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_auditor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_supervisor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              }
            },
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTNCP 20',
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

    assert_not_nil assigns(:potential_nonconformity)
    assert_redirected_to edit_potential_nonconformity_url(assigns(:potential_nonconformity))
    assert_equal 'NCP020', assigns(:potential_nonconformity).review_code
  end

  test 'follow up pdf' do
    perform_auth
    potential_nonconformity = PotentialNonconformity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_potential_nonconformity).id)

    assert_nothing_raised(Exception) do
      get :follow_up_pdf, :id => potential_nonconformity.id
    end

    assert_redirected_to potential_nonconformity.relative_follow_up_pdf_path
  end

  test 'undo reiteration' do
    perform_auth
    review = Review.find(reviews(:review_with_conclusion).id)

    assert_difference 'review.finding_review_assignments.count' do
      review.finding_review_assignments.create(
        :finding_id => findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id
      )
    end

    potential_nonconformity = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_potential_nonconformity).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
    repeated_of_original_state = repeated_of.state

    assert !repeated_of.repeated?
    assert potential_nonconformity.update(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert potential_nonconformity.reload.repeated_of

    patch :undo_reiteration, :id => potential_nonconformity.to_param
    assert_redirected_to edit_potential_nonconformity_url(potential_nonconformity)

    assert !repeated_of.reload.repeated?
    assert_nil potential_nonconformity.reload.repeated_of
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
    finding = Finding.find(findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_potential_nonconformity).id)
    perform_auth
    get :auto_complete_for_finding_relation, {
      :q => 'NCP001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size
    assert findings.all? { |f| (f['label'] + f['informal']).match /NCP001/i }

    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_notify_potential_nonconformity).id)

    get :auto_complete_for_finding_relation, {
      :q => 'NCP001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Se excluye la no conformidad 001 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /NCP001/i }

    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'NCP001, 1 2 3',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo NCP01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /NCP001.*1 2 3/i }

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
    get :auto_complete_for_control_objective_item, {
      :q => 'dependencia',
      :review_id => reviews(:review_with_conclusion).id,
      :format => :json
    }
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, cois.size # bcra_A4609_security_management_responsible_dependency_item_editable
    assert cois.all? { |f| (f['label'] + f['informal']).match /dependencia/i }
    assert_equal(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item_editable).id,
      cois.first['id']
    )

    get :auto_complete_for_control_objective_item, {
      :q => 'x_none',
      :review_id => reviews(:review_with_conclusion).id,
      :format => :json
    }
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, cois.size # Sin resultados
  end
end
