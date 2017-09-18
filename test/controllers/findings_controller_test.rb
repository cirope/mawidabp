require 'test_helper'

# Pruebas para el controlador de hallazgos
class FindingsControllerTest < ActionController::TestCase
  fixtures :findings, :users

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      :params => {
        :completed => 'complete',
        :id => findings(:unanswered_weakness).to_param
      }
    }
    public_actions = []
    private_actions = [
      [:get, :index, :params => { :completed => 'incomplete' }],
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
    get :index, :params => { :completed => 'incomplete' }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_template 'findings/index'
  end

  test 'list findings for follow_up_committee' do
    login user: users(:committee_user)
    get :index, :params => { :completed => 'incomplete' }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_template 'findings/index'
  end

  test 'list findings with search and sort' do
    login
    get :index, :params => {
      :completed => 'incomplete',
      :search => {
        :query => '1 2 4 y w',
        :columns => ['title', 'review'],
        :order => 'review'
      }
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
    get :index, :params => {
      :completed => 'incomplete',
      :search => {
        :query => "> #{I18n.l(4.days.ago.to_date, :format => :minimal)}",
        :columns => ['review', 'issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 4, assigns(:findings).count
    assert assigns(:findings).all? {|f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date}
    assert_template 'findings/index'
  end

  test 'list findings for user' do
    login
    user = User.find(users(:first_time_user).id)
    get :index, :params => {
      :completed => 'incomplete',
      :user_id => user.id
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_template 'findings/index'
  end

  test 'list findings for responsible auditor' do
    login
    user = User.find(users(:first_time_user).id)
    get :index, :params => {
      :completed => 'incomplete',
      :user_id => user.id,
      :as_responsible => true
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
    assert_template 'findings/index'
  end

  test 'list findings for process owner' do
    user = users :audited_user

    login user: user
    get :index, :params => {
      :completed => 'incomplete',
      :as_owner => true
    }
    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| f.finding_user_assignments.owners.map(&:user).include?(user) }
  end

  test 'list findings for specific ids' do
    login
    ids = [
      findings(:being_implemented_weakness).id,
      findings(:unconfirmed_for_notification_weakness).id
    ]

    get :index, :params => {
      :completed => 'incomplete',
      :ids => ids
    }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
    assert_template 'findings/index'
  end

  test 'list findings as CSV' do
    login
    get :index, :params => {
      :completed => 'incomplete',
      :format => :csv
    }
    assert_response :success
    assert_equal "#{Mime[:csv]}", @response.content_type
  end

  test 'list findings as PDF' do
    login
    get :index, :params => {
      :completed => 'incomplete',
      :format => :pdf
    }
    assert_redirected_to /\/private\/.*\/findings\/.*\.pdf$/
    assert_equal "#{Mime[:pdf]}", @response.content_type
  end

  test 'list findings as corporate user' do
    organization = organizations :twitter

    login prefix: organization.prefix

    get :index, :params => { :completed => 'incomplete' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert(assigns(:findings).any? { |finding| finding.organization_id != organization.id })
    assert_template 'findings/index'
  end

  test 'show finding' do
    login
    get :show, :params => {
      :completed => 'incomplete',
      :id => findings(:unanswered_weakness).id
    }
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/show'
  end

  test 'show finding for follow_up_committee' do
    login user: users(:committee_user)
    get :show, :params => {
      :completed => 'incomplete',
      :id => findings(:being_implemented_oportunity).id
    }
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/show'
  end

  test 'edit finding' do
    login user: users(:auditor_user)
    get :edit, :params => {
      :completed => 'incomplete',
      :id => findings(:unanswered_weakness).id
    }
    assert_response :success
    assert_not_nil assigns(:finding)
    assert_template 'findings/edit'

    auditor_response = @response.body.dup

    login user: users(:audited_user)
    get :edit, :params => {
      :completed => 'incomplete',
      :id => findings(:unanswered_weakness).id
    }
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
      get :edit, :params => {
        :completed => 'complete',
        :id => findings(:being_implemented_weakness_on_final).id
      }
    end
  end

  test 'unauthorized edit incomplete finding' do
    login user: users(:audited_user)

    # No está autorizado el usuario a ver la observación por estar incompleta
    assert_raise ActiveRecord::RecordNotFound do
      get :edit, :params => {
        :completed => 'incomplete',
        :id => findings(:incomplete_weakness).id
      }
    end
  end

  test 'update finding' do
    login user: users(:supervisor_user)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    difference_counts = ['WorkPaper.count', 'FindingAnswer.count', 'Cost.count',
                         'ActionMailer::Base.deliveries.size',
                         'FindingRelation.count', 'BusinessUnitFinding.count',
                         'Tagging.count']

    assert_no_difference 'Finding.count' do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          patch :update, :params => {
            :completed => 'incomplete',
            :id => findings(:unconfirmed_weakness).id,
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
                  :id => finding_user_assignments(:unconfirmed_weakness_bare_user).id,
                  :user_id => users(:bare_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:unconfirmed_weakness_audited_user).id,
                  :user_id => users(:audited_user).id,
                  :process_owner => '1'
                },
                {
                  :id => finding_user_assignments(:unconfirmed_weakness_auditor_user).id,
                  :user_id => users(:auditor_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:unconfirmed_weakness_manager_user).id,
                  :user_id => users(:manager_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:unconfirmed_weakness_supervisor_user).id,
                  :user_id => users(:supervisor_user).id,
                  :process_owner => '0'
                },
                {
                  :id => finding_user_assignments(:unconfirmed_weakness_administrator_user).id,
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
                  :related_finding_id => findings(:unanswered_weakness).id
                }
              ],
              :taggings_attributes => [
                {
                  :tag_id => tags(:important).id
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
        patch :update, :params => {
          :completed => 'incomplete',
          :id => findings(:unconfirmed_weakness).id,
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
                :related_finding_id => findings(:unanswered_weakness).id
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
        patch :update, :params => {
          :completed => 'incomplete',
          :id => findings(:unconfirmed_weakness).id,
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
                :id => finding_user_assignments(:unconfirmed_weakness_bare_user).id,
                :user_id => users(:bare_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:unconfirmed_weakness_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              {
                :id => finding_user_assignments(:unconfirmed_weakness_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:unconfirmed_weakness_manager_user).id,
                :user_id => users(:manager_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:unconfirmed_weakness_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:unconfirmed_weakness_administrator_user).id,
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
    finding = Finding.find(findings(:unconfirmed_weakness).id)

    assert_nothing_raised do
      get :follow_up_pdf, :params => {
        :completed => 'incomplete',
        :id => finding.id
      }
    end

    assert_redirected_to finding.relative_follow_up_pdf_path
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(:being_implemented_weakness_on_draft).id)

    login
    get :auto_complete_for_finding_relation, :params => {
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

    finding = Finding.find(findings(:unconfirmed_for_notification_weakness).id)

    get :auto_complete_for_finding_relation, :params => {
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

    get :auto_complete_for_finding_relation, :params => {
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

    get :auto_complete_for_finding_relation, :params => {
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

  test 'auto complete for tagging' do
    login

    get :auto_complete_for_tagging, :params => {
      :q => 'impor',
      :completed => 'incomplete',
      :kind => 'finding',
      :format => :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /impor/i }

    get :auto_complete_for_tagging, :params => {
      :q => 'x_none',
      :completed => 'incomplete',
      :kind => 'finding',
      :format => :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, tags.size # Sin resultados
  end
end
