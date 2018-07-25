require 'test_helper'

# Pruebas para el controlador de debilidades
class WeaknessesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    id_param = {
      params: {
        id: findings(:unanswered_weakness).to_param
      }
    }
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

  test 'list weaknesses' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_template 'weaknesses/index'
  end

  test 'list weaknesses with search and sort' do
    login
    get :index, params: {
      search: {
        query: '1 2 4',
        columns: ['title', 'review'],
        order: 'review'
      }
    }
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_equal 2, assigns(:weaknesses).count
    assert(assigns(:weaknesses).all? do |w|
      w.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:weaknesses).map {|w| w.review.identification}.sort,
      assigns(:weaknesses).map {|w| w.review.identification}
    assert_template 'weaknesses/index'
  end

  test 'list weaknesses for specific ids' do
    login
    ids = [
      findings(:unconfirmed_weakness).id,
      findings(:being_implemented_weakness_on_draft).id
    ]

    get :index, params: { ids: ids }
    assert_response :success
    assert_not_nil assigns(:weaknesses)
    assert_equal 2, assigns(:weaknesses).count
    assert assigns(:weaknesses).all? { |w| ids.include?(w.id) }
    assert_template 'weaknesses/index'
  end

  test 'list weaknesses as CSV' do
    login
    get :index, as: :csv

    assert_response :success
    assert_equal "#{Mime[:csv]}", @response.content_type
  end

  test 'show weakness' do
    login
    get :show, params: {
      id: findings(:unanswered_weakness).id
    }
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_template 'weaknesses/show'
  end

  test 'show weakness in json' do
    weakness = findings :unanswered_weakness

    login
    get :show, :params => {
      :completed => 'incomplete',
      :id => weakness.id
    }, :as => :json
    assert_response :success
    assert_not_nil assigns(:weakness)

    decoded_weakness = ActiveSupport::JSON.decode @response.body

    assert_equal weakness.id, decoded_weakness['id']
  end

  test 'new weakness' do
    login
    get :new, params: {
      control_objective_item: control_objective_items(:management_dependency_item_editable).id
    }
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_template 'weaknesses/new'
  end

  test 'create weakness' do
    counts_array = [
      'Weakness.count',
      'WorkPaper.count',
      'FindingRelation.count',
      'Achievement.count',
      'BusinessUnitFinding.count',
      'Tagging.count',
      'Task.count',
      'Comment.count'
    ]

    login

    assert_difference counts_array do
      post :create, params: {
        weakness: {
          control_objective_item_id:
            control_objective_items(:impact_analysis_item_editable).id,
          review_code: 'O020',
          title: 'Title',
          description: 'New description',
          answer: 'New answer',
          audit_comments: 'New audit comments',
          state: Finding::STATUS[:being_implemented],
          origination_date: 1.day.ago.to_date.to_s(:db),
          solution_date: '',
          audit_recommendations: 'New proposed action',
          effect: 'New effect',
          risk: Weakness.risks_values.first,
          priority: Weakness.priorities_values.first,
          follow_up_date: 2.days.from_now.to_date,
          business_unit_ids: [business_units(:business_unit_three).id],
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          finding_user_assignments_attributes: [
            {
              user_id: users(:bare).id, process_owner: '0'
            }, {
              user_id: users(:audited).id, process_owner: '1'
            }, {
              user_id: users(:auditor).id, process_owner: '0'
            }, {
              user_id: users(:manager).id, process_owner: '0'
            }, {
              user_id: users(:supervisor).id, process_owner: '0'
            }, {
              user_id: users(:administrator).id, process_owner: '0'
            }
          ],
          achievements_attributes: [
            {
              benefit_id: benefits(:productivity).id,
              amount: '2000.01'
            }
          ],
          work_papers_attributes: [
            {
              name: 'New workpaper name',
              code: 'PTO 20',
              number_of_pages: '10',
              description: 'New workpaper description',
              file_model_attributes: {
                file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
              }
            }
          ],
          taggings_attributes: [
            {
              tag_id: tags(:important).id
            }
          ],
          finding_relations_attributes: [
            {
              description: 'Duplicated',
              related_finding_id: findings(:unanswered_weakness).id
            }
          ],
          tasks_attributes: [
            {
              code: '01',
              description: 'New task',
              status: 'pending',
              due_on: I18n.l(Time.zone.tomorrow)
            }
          ],
          comments_attributes: [
            {
              comment: 'Test',
              user_id: users(:administrator).id
            }
          ]
        }
      }
    end
  end

  test 'edit weakness' do
    login
    get :edit, params: {
      id: findings(:unanswered_weakness).id
    }
    assert_response :success
    assert_not_nil assigns(:weakness)
    assert_template 'weaknesses/edit'
  end

  test 'update weakness' do
    counts_array = [
      'WorkPaper.count',
      'FindingRelation.count',
      'Task.count'
    ]

    login
    assert_no_difference 'Weakness.count' do
      assert_difference counts_array do
        patch :update, params: {
          id: findings(:unanswered_weakness).id,
          weakness: {
            control_objective_item_id:
              control_objective_items(:impact_analysis_item).id,
            review_code: 'O020',
            title: 'Title',
            description: 'Updated description',
            answer: 'Updated answer',
            audit_comments: 'Updated audit comments',
            state: Finding::STATUS[:unanswered],
            origination_date: 1.day.ago.to_date.to_s(:db),
            solution_date: '',
            audit_recommendations: 'Updated proposed action',
            effect: 'Updated effect',
            risk: Weakness.risks_values.first,
            priority: Weakness.priorities_values.first,
            follow_up_date: '',
            compliance: 'no',
            operational_risk: ['internal fraud'],
            impact: ['econimic', 'regulatory'],
            internal_control_components: ['risk_evaluation', 'monitoring'],
            finding_user_assignments_attributes: [
              {
                id: finding_user_assignments(:unanswered_weakness_bare).id,
                user_id: users(:bare).id,
                process_owner: '0'
              }, {
                id: finding_user_assignments(:unanswered_weakness_audited).id,
                user_id: users(:audited).id,
                process_owner: '1'
              }, {
                id: finding_user_assignments(:unanswered_weakness_auditor).id,
                user_id: users(:auditor).id,
                process_owner: '0'
              }, {
                id: finding_user_assignments(:unanswered_weakness_manager).id,
                user_id: users(:manager).id,
                process_owner: '0'
              }, {
                id: finding_user_assignments(:unanswered_weakness_supervisor).id,
                user_id: users(:supervisor).id,
                process_owner: '0'
              }, {
                id: finding_user_assignments(:unanswered_weakness_administrator).id,
                user_id: users(:administrator).id,
                process_owner: '0'
              }
            ],
            work_papers_attributes: [
              {
                name: 'New workpaper name',
                code: 'PTO 20',
                number_of_pages: '10',
                description: 'New workpaper description',
                file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(
                    TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            ],
            finding_relations_attributes: [
              {
                description: 'Duplicated',
                related_finding_id: findings(:unanswered_weakness).id
              }
            ],
            tasks_attributes: [
              {
                code: '01',
                description: 'New task',
                status: 'pending',
                due_on: I18n.l(Time.zone.tomorrow)
              }
            ]
          }
        }
      end
    end

    assert_not_nil assigns(:weakness)
    assert_redirected_to edit_weakness_url(assigns(:weakness))
    assert_equal 'O020', assigns(:weakness).review_code
  end

  test 'undo reiteration' do
    login
    weakness = Finding.find(findings(:unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(:being_implemented_weakness).id)
    repeated_of_original_state = repeated_of.state

    assert !repeated_of.repeated?
    assert weakness.update(repeated_of_id: repeated_of.id)
    assert repeated_of.reload.repeated?
    assert weakness.reload.repeated_of

    patch :undo_reiteration, params: { id: weakness.to_param }
    assert_redirected_to edit_weakness_url(weakness)

    assert !repeated_of.reload.repeated?
    assert_nil weakness.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'state changed' do
    login

    get :state_changed, xhr: true, params: {
      state: Finding::STATUS[:being_implemented]
    }, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'weakness template changed' do
    login

    get :weakness_template_changed, xhr: true, params: {
      id: weakness_templates(:security).id
    }, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]

    get :weakness_template_changed, xhr: true, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(:being_implemented_weakness_on_draft).id)

    login
    get :auto_complete_for_finding_relation, params: {
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, findings.size
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    finding = Finding.find(findings(:unconfirmed_for_notification_weakness).id)

    get :auto_complete_for_finding_relation, params: {
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    get :auto_complete_for_finding_relation, params: {
      completed: 'incomplete',
      q: 'O001, 1 2 3',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }

    get :auto_complete_for_finding_relation, params: {
      q: 'x_none',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, findings.size # No results
  end

  test 'auto complete for tagging' do
    login

    get :auto_complete_for_tagging, params: {
      :q => 'impor',
      :kind => 'finding'
    }, :as => :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /impor/i }

    get :auto_complete_for_tagging, params: {
      :q => 'x_none',
      :kind => 'finding'
    }, :as => :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, tags.size # No results
  end

  test 'auto complete for control objective item' do
    login
    get :auto_complete_for_control_objective_item, params: {
      q: 'dependencia',
      review_id: reviews(:review_with_conclusion).id
    }, as: :json
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, cois.size # management_dependency_item_editable
    assert cois.all? { |f| (f['label'] + f['informal']).match /dependencia/i }
    assert_equal(
      control_objective_items(:management_dependency_item_editable).id,
      cois.first['id']
    )

    get :auto_complete_for_control_objective_item, params: {
      q: 'x_none',
      review_id: reviews(:review_with_conclusion).id
    }, as: :json
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, cois.size # No results
  end

  test 'auto complete for weakness template' do
    login

    get :auto_complete_for_weakness_template, params: { q: 'sec' }, as: :json

    assert_response :success

    wts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, wts.size # security
    assert wts.all? { |f| f['label'].match /sec/i }
    assert_equal weakness_templates(:security).id, wts.first['id']

    get :auto_complete_for_weakness_template, params: { q: 'x_none' }, as: :json

    assert_response :success

    wts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, wts.size # No results
  end
end
