require 'test_helper'

class NonconformitiesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    id_param = {:id => findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:patch, :undo_reiteration, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list nonconformities' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:nonconformities)
    assert_template 'nonconformities/index'
  end

  test 'list nonconformities with search and sort' do
    login
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['title', 'review'],
      :order => 'review'
    }
    assert_response :success
    assert_not_nil assigns(:nonconformities)
    assert_equal 2, assigns(:nonconformities).count
    assert(assigns(:nonconformities).all? do |w|
      w.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:nonconformities).map {|w| w.review.identification}.sort,
      assigns(:nonconformities).map {|w| w.review.identification}
    assert_template 'nonconformities/index'
  end

  test 'list nonconformities for specific ids' do
    login
    ids = [
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_nonconformity).id,
      findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_nonconformity).id
    ]

    get :index, :ids => ids
    assert_response :success
    assert_not_nil assigns(:nonconformities)
    assert_equal 2, assigns(:nonconformities).count
    assert assigns(:nonconformities).all? { |w| ids.include?(w.id) }
    assert_template 'nonconformities/index'
  end

  test 'edit nonconformity when search match only one result' do
    login
    get :index, :search => {
      :query => '1 2 4 y 1nc',
      :columns => ['title', 'review']
    }
    assert_redirected_to nonconformity_url(
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_nonconformity))
    assert_not_nil assigns(:nonconformities)
    assert_equal 1, assigns(:nonconformities).count
  end

  test 'show nonconformity' do
    login
    get :show, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).id
    assert_response :success
    assert_not_nil assigns(:nonconformity)
    assert_template 'nonconformities/show'
  end

  test 'new nonconformity' do
    login
    get :new, :control_objective_item => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:nonconformity)
    assert_template 'nonconformities/new'
  end

  test 'create nonconformity' do
    counts_array = ['Nonconformity.count', 'WorkPaper.count',
      'FindingRelation.count']

    login
    assert_difference counts_array do
      post :create, {
        :nonconformity => {
          :control_objective_item_id => control_objective_items(
            :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
          :review_code => 'NC020',
          :title => 'Title',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :state => Finding::STATUS[:being_implemented],
          :origination_date => 1.day.ago.to_date.to_s(:db),
          :solution_date => '',
          :audit_recommendations => 'New proposed action',
          :effect => 'New effect',
          :risk => Nonconformity.risks_values.first,
          :priority => Nonconformity.priorities_values.first,
          :follow_up_date => 2.days.from_now.to_date,
          :finding_user_assignments_attributes => [
            {
              :user_id => users(:bare_user).id, :process_owner => '0'
            },
            {
              :user_id => users(:audited_user).id, :process_owner => '1'
            },
            {
              :user_id => users(:auditor_user).id, :process_owner => '0'
            },
            {
              :user_id => users(:manager_user).id, :process_owner => '0'
            },
            {
              :user_id => users(:supervisor_user).id, :process_owner => '0'
            },
            {
              :user_id => users(:administrator_user).id, :process_owner => '0'
            }
          ],
          :work_papers_attributes => [
            {
              :name => 'New workpaper name',
              :code => 'PTNC 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:cirope).id,
              :file_model_attributes => {
                :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                  'text/plain')
              }
            }
	  ],
          :finding_relations_attributes => [
            {
              :description => 'Duplicated',
              :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).id
            }
	  ]
        }
      }
    end
  end

  test 'edit nonconformity' do
    login
    get :edit, :id => findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).id
    assert_response :success
    assert_not_nil assigns(:nonconformity)
    assert_template 'nonconformities/edit'
  end

  test 'update nonconformity' do
    login
    assert_no_difference 'Nonconformity.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        patch :update, {
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_nonconformity).id,
          :nonconformity => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'NC020',
            :title => 'Title',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :solution_date => '',
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => Nonconformity.risks_values.first,
            :priority => Nonconformity.priorities_values.first,
            :follow_up_date => '',
            :finding_user_assignments_attributes => [
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_nonconformity_bare_user).id,
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_nonconformity_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_nonconformity_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_nonconformity_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
	    ],
            :work_papers_attributes => [
              {
                :name => 'New workpaper name',
                :code => 'PTNC 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:cirope).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(
                    TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
	    ],
            :finding_relations_attributes => [
              {
                :description => 'Duplicated',
                :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).id
              }
	    ]
          }
        }
      end
    end

    assert_not_nil assigns(:nonconformity)
    assert_redirected_to edit_nonconformity_url(assigns(:nonconformity))
    assert_equal 'NC020', assigns(:nonconformity).review_code
  end

  test 'follow up pdf' do
    login
    nonconformity = Nonconformity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_nonconformity).id)

    assert_nothing_raised do
      get :follow_up_pdf, :id => nonconformity.id
    end

    assert_redirected_to nonconformity.relative_follow_up_pdf_path
  end

  test 'undo reiteration' do
    login
    nonconformity = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_nonconformity_unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_nonconformity_being_implemented).id)
    repeated_of_original_state = repeated_of.state

    assert !repeated_of.repeated?
    assert nonconformity.update(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert nonconformity.reload.repeated_of

    patch :undo_reiteration, :id => nonconformity.to_param
    assert_redirected_to edit_nonconformity_url(nonconformity)

    assert !repeated_of.reload.repeated?
    assert_nil nonconformity.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_nonconformity).id)

    login
    get :auto_complete_for_finding_relation, {
      :q => 'NC001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, findings.size
    assert findings.all? { |f| (f['label'] + f['informal']).match /NC001/i }

    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_nonconformity_unconfirmed_for_notification).id)

    get :auto_complete_for_finding_relation, {
      :q => 'NC001',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /NC001/i }

    get :auto_complete_for_finding_relation, {
      :completed => 'incomplete',
      :q => 'NC001, 1 2 3',
      :finding_id => finding.id,
      :review_id => finding.review.id,
      :format => :json
    }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /NC001.*1 2 3/i }

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
    login
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
