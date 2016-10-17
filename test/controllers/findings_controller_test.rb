require 'test_helper'

# Pruebas para el controlador de hallazgos
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
      [:patch, :update, id_param]
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

  test 'list findings' do
    login
    get :index, :completed => 'incomplete'
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_template 'findings/index'
  end

  test 'list findings for follow_up_committee' do
    login user: users(:committee_user)
    get :index, :completed => 'incomplete'
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_template 'findings/index'
  end

  test 'list findings with search and sort' do
    login
    get :index, :completed => 'incomplete', :search => {
      :query => '1 2 4 y w',
      :columns => ['title', 'review'],
      :order => 'review'
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? {|f| f.review.identification.match(/1 2 4/i)}
    assert_equal assigns(:findings).map {|f| f.review.identification}.sort,
      assigns(:findings).map {|f| f.review.identification}
    assert_template 'findings/index'
  end

  test 'list findings with search by date and sort' do
    login
    get :index, :completed => 'incomplete', :search => {
      :query => "> #{I18n.l(4.days.ago.to_date, :format => :minimal)}",
      :columns => ['review', 'issue_date']
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 5, assigns(:findings).count
    assert assigns(:findings).all? {|f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date}
    assert_template 'findings/index'
  end

  test 'list findings for user' do
    login
    user = User.find(users(:first_time_user).id)
    get :index, :completed => 'incomplete', :user_id => user.id
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_template 'findings/index'
  end

  test 'list findings for responsible auditor' do
    login
    user = User.find(users(:first_time_user).id)
    get :index, :completed => 'incomplete', :user_id => user.id, :as_responsible => true
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_template 'findings/index'
  end

  test 'list findings for process owner' do
    user = users :audited_user

    login user: user
    get :index, :completed => 'incomplete', :as_owner => true
    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| f.finding_user_assignments.owners.map(&:user).include?(user) }
  end

  test 'list findings for specific ids' do
    login
    ids = [
      findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id,
      findings(:iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id
    ]

    get :index, :completed => 'incomplete', :ids => ids
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
    assert_template 'findings/index'
  end

  test 'list findings as CSV' do
    login
    get :index, :completed => 'incomplete', :format => :csv
    assert_response :success
    assert_equal "#{Mime::CSV}; charset=utf-8", @response.content_type
  end

  test 'list findings as corporate user' do
    organization = organizations :twitter

    login prefix: organization.prefix

    get :index, :completed => 'incomplete'

    assert_response :success
    assert_not_nil assigns(:findings)
    assert(assigns(:findings).any? { |finding| finding.organization_id != organization.id })
    assert_template 'findings/index'
  end

  test 'edit finding when search match only one result' do
    login
    get :index, :completed => 'incomplete', :search => {
      :query => '1 2 4 y 1w',
      :columns => ['title', 'review']
    }

    assert_redirected_to finding_url('incomplete',
      findings(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness))
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).count
  end

  test 'show finding' do
    login
    get :show, :completed => 'incomplete',
      :id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/show'
  end

  test 'show finding for follow_up_committee' do
    login user: users(:committee_user)
    get :show, :completed => 'incomplete', :id => findings(
      :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_oportunity).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/show'
  end

  test 'edit finding' do
    login
    get :edit, :completed => 'incomplete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/edit'

    auditor_response = @response.body.dup

    login user: users(:audited_user)
    get :edit, :completed => 'incomplete', :id =>
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/edit'
    # Diferentes forms
    assert_not_equal auditor_response, @response.body
  end

  test 'unauthorized edit finding' do
    login user: users(:audited_second_user)

    # No está autorizado el usuario a ver la observación
    assert_raise ActiveRecord::RecordNotFound do
      get :edit, :completed => 'complete',
        :id => findings(:iso_27000_security_policy_3_1_item_weakness).id
    end
  end

  test 'unauthorized edit incomplete finding' do
    login user: users(:audited_user)

    # No está autorizado el usuario a ver la observación por estar incompleta
    assert_raise ActiveRecord::RecordNotFound do
      get :edit, :completed => 'incomplete',
        :id => findings(:iso_27000_security_organization_4_2_item_editable_weakness_incomplete).id
    end
  end

  test 'update finding' do
    login user: users(:supervisor_user)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    difference_counts = ['WorkPaper.count', 'FindingAnswer.count', 'Cost.count',
                         'ActionMailer::Base.deliveries.size',
                         'FindingRelation.count', 'BusinessUnitFinding.count']

    assert_no_difference 'Finding.count' do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          patch :update, {
            :completed => 'incomplete',
            :id => findings(
              :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
            :finding => {
              :control_objective_item_id => control_objective_items(
                :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
              :review_code => 'O020',
              :title => 'Title',
              :description => 'Updated description',
              :answer => 'Updated answer',
              :audit_comments => 'Updated audit comments',
              :state => Finding::STATUS[:unconfirmed],
              :origination_date => 1.day.ago.to_date.to_s(:db),
              :solution_date => '',
              :audit_recommendations => 'Updated proposed action',
              :effect => 'Updated effect',
              :risk => Finding.risks_values.first,
              :priority => Finding.priorities_values.first,
              :follow_up_date => '',
              :business_unit_ids => [business_units(:business_unit_three).id],
              :finding_user_assignments_attributes => [
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id,
                  :user_id => users(:bare_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id,
                  :user_id => users(:audited_user).id,
                  :process_owner => '1'
                },
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id,
                  :user_id => users(:auditor_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id,
                  :user_id => users(:manager_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id,
                  :user_id => users(:supervisor_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id,
                  :user_id => users(:administrator_user).id,
                  :process_owner => '0'
                }
              ],
              :work_papers_attributes => [
                {
                  :name => 'New workpaper name',
                  :code => 'PTSO 20',
                  :number_of_pages => '10',
                  :description => 'New workpaper description',
                  :file_model_attributes => {
                    :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                      'text/plain')
                  }
                }
              ],
              :finding_answers_attributes => [
                {
                  :answer => 'New answer',
                  :auditor_comments => 'New auditor comments',
                  :user_id => users(:supervisor_user).id,
                  :notify_users => '1',
                  :file_model_attributes => {
                    :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                      'text/plain')
                  }
                }
              ],
              :finding_relations_attributes => [
                {
                  :description => 'Duplicated',
                  :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
                }
              ],
              :costs_attributes => [
                {
                  :cost => '12.5',
                  :cost_type => 'audit',
                  :description => 'New cost description',
                  :user_id => users(:administrator_user).id
                }
              ]
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
    login user: users(:audited_user)
    no_difference_count = ['Finding.count', 'WorkPaper.count',
      'FindingRelation.count']
    difference_count = ['FindingAnswer.count', 'Cost.count', 'FileModel.count']

    assert_no_difference no_difference_count do
      assert_difference difference_count do
        patch :update, {
          :completed => 'incomplete',
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
          :finding => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
            :review_code => 'O020',
            :title => 'Title',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :origination_date => 35.day.ago.to_date.to_s(:db),
            :solution_date => 31.days.from_now.to_date,
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => Finding.risks_values.first,
            :priority => Finding.priorities_values.first,
            :follow_up_date => 3.days.from_now.to_date,
            :finding_user_assignments_attributes => [
              {
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              {
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              {
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              {
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              {
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              {
                :user_id => users(:administrator_user).id,
                :process_owner => '0'
              }
            ],
            :work_papers_attributes => [
              {
                :name => 'New workpaper name',
                :code => 'PTSO 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:cirope).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                    'text/plain')
                }
              }
            ],
            :finding_answers_attributes => [
              {
                :answer => 'New answer',
                :auditor_comments => 'New audited comments',
                :commitment_date => I18n.l(Date.tomorrow),
                :user_id => users(:audited_user).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                    'text/plain')
                }
              }
            ],
            :finding_relations_attributes => [
              {
                :description => 'Duplicated',
                :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
              }
            ],
            :costs_attributes => [
              {
                :cost => '12.5',
                :cost_type => 'audit',
                :description => 'New cost description',
                :user_id => users(:administrator_user).id
              }
            ]
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_not_equal 'Updated description', assigns(:finding).description
  end

  test 'update finding and notify to the new user' do
    login user: users(:supervisor_user)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'Finding.count' do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        patch :update, {
          :completed => 'incomplete',
          :id => findings(
            :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id,
          :finding => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_data_proccessing_impact_analisys_item).id,
            :review_code => 'O020',
            :title => 'Title',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:unconfirmed],
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :solution_date => '',
            :audit_recommendations => 'Updated proposed action',
            :effect => 'Updated effect',
            :risk => Finding.risks_values.first,
            :priority => Finding.priorities_values.first,
            :follow_up_date => '',
            :users_for_notification => [users(:bare_user).id],
            :finding_user_assignments_attributes => [
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_bare_user).id,
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_manager_user).id,
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:bcra_A4609_data_proccessing_impact_analisys_editable_weakness_administrator_user).id,
                :user_id => users(:administrator_user).id,
                :process_owner => '0'
              }
            ]
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', assigns(:finding))
    assert_not_nil assigns(:finding)
    assert_equal 'Updated description', assigns(:finding).description
  end

  test 'follow up pdf' do
    login
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    assert_nothing_raised do
      get :follow_up_pdf, :completed => 'incomplete', :id => finding.id
    end

    assert_redirected_to finding.relative_follow_up_pdf_path
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)

    login
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
