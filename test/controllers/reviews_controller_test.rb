require 'test_helper'

# Pruebas para el controlador de informes
class ReviewsControllerTest < ActionController::TestCase
  fixtures :reviews, :plan_items, :periods, :control_objectives, :controls

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      params: {
        id: reviews(:current_review).to_param
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
      [:delete, :destroy, id_param]
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

  test 'list reviews' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_not_equal 0, assigns(:reviews).count
    assert_template 'reviews/index'
  end

  test 'list reviews with search' do
    login
    get :index, params: {
      search: {
        query: '1 2',
        columns: ['identification', 'project']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 5, assigns(:reviews).count
    assert_template 'reviews/index'
  end

  test 'list reviews with search on tags' do
    support_tags = ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'

    skip unless support_tags

    login
    get :index, params: {
      search: {
        query: 'high priority',
        columns: ['tags']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 2, assigns(:reviews).count
    assert_template 'reviews/index'

    get :index, params: {
      search: {
        query: 'high priority and for rev',
        columns: ['tags']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 1, assigns(:reviews).count
    assert_template 'reviews/index'
  end

  test 'list reviews with search on audit team' do
    login
    get :index, params: {
      search: {
        query: 'sup',
        columns: ['audit_team']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 6, assigns(:reviews).count
    assert_template 'reviews/index'

    get :index, params: {
      search: {
        query: 'first',
        columns: ['audit_team']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 1, assigns(:reviews).count
    assert_template 'reviews/index'

    # No search by audited kind
    get :index, params: {
      search: {
        query: 'audited',
        columns: ['audit_team']
      }
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 0, assigns(:reviews).count
    assert_template 'reviews/index'
  end

  test 'show review' do
    login
    get :show, params: {
      id: reviews(:current_review).id
    }
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/show'
  end

  test 'new review' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/new'
  end

  test 'clone review' do
    login
    review = Review.find reviews(:current_review).id

    get :new, params: { clone_from: review.id }
    assert_response :success
    assert_not_nil assigns(:review)
    assert review.control_objective_items.size > 0
    assert_equal review.control_objective_items.size,
      assigns(:review).control_objective_items.size
    assert review.review_user_assignments.size > 0
    assert_equal review.review_user_assignments.size,
      assigns(:review).review_user_assignments.size
    assert_template 'reviews/new'
  end

  test 'create review' do
    expected_coi_count = ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION ? 5 : 3

    login
    assert_difference ['Review.count', 'FindingReviewAssignment.count', 'Tagging.count'] do
      # Se crean 2 con 'best_practice_ids', 2 con 'process_control_ids' y uno con 'control_objective_ids'
      assert_difference 'ControlObjectiveItem.count', expected_coi_count do
        assert_difference 'FileModel.count' do
          assert_difference 'ReviewUserAssignment.count', 4 do
            post :create, params: {
              review: {
                identification: 'New Identification',
                description: 'New Description',
                survey: 'New survey',
                period_id: periods(:current_period).id,
                plan_item_id: plan_items(:past_plan_item_3).id,
                scope: 'committee',
                risk_exposure: 'high',
                manual_score: 800,
                include_sox: 'no',
                best_practice_ids: [best_practices(:bcra_A4609).id],
                process_control_ids: [process_controls(:security_management).id],
                control_objective_ids: [control_objectives(:security_policy_3_1).id],
                file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                },
                finding_review_assignments_attributes: [
                  {
                    finding_id: findings(:unanswered_weakness).id.to_s
                  }
                ],
                review_user_assignments_attributes: [
                  {
                    assignment_type: ReviewUserAssignment::TYPES[:auditor],
                    user_id: users(:first_time).id
                  }, {
                    assignment_type:
                      ReviewUserAssignment::TYPES[:supervisor],
                    user_id: users(:supervisor).id
                  }, {
                    assignment_type: ReviewUserAssignment::TYPES[:manager],
                    user_id: users(:supervisor_second).id
                  }, {
                    assignment_type: ReviewUserAssignment::TYPES[:audited],
                    user_id: users(:audited).id
                  }
                ],
                taggings_attributes: [
                  {
                    tag_id: tags(:high_priority).id
                  }
                ]
              }
            }
          end
        end
      end
    end
  end

  test 'edit review' do
    login
    get :edit, params: { id: reviews(:current_review).id }
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/edit'
  end

  test 'update review' do
    counts_array = ['Review.count', 'ControlObjectiveItem.count',
      'ReviewUserAssignment.count', 'FileModel.count', 'Control.count']
    login
    assert_no_difference counts_array do
      patch :update, params: {
        id: reviews(:review_with_conclusion).id,
        review: {
          identification: 'Updated Identification',
          description: 'Updated Description',
          period_id: periods(:current_period).id,
          plan_item_id: plan_items(:current_plan_item_2).id,
          scope: 'committee',
          risk_exposure: 'high',
          manual_score: 800,
          include_sox: 'no',
          review_user_assignments_attributes: [
            {
              id: review_user_assignments(:review_with_conclusion_bare_auditor).id,
              assignment_type: ReviewUserAssignment::TYPES[:auditor],
              user_id: users(:bare).id
            }
          ],
          control_objective_items_attributes: [
            {
              id: control_objective_items(:management_dependency_item_editable).id,
              order_number: 1
            }
          ]
        }
      }
    end

    control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:management_dependency_item_editable).id)

    assert_redirected_to edit_review_url(reviews(:review_with_conclusion).id)
    assert_not_nil assigns(:review)
    assert_equal 'Updated Description', assigns(:review).description
  end

  test 'destroy review' do
    skip if SHOW_REVIEW_AUTOMATIC_IDENTIFICATION

    login

    assert_difference 'Review.count', -1 do
      delete :destroy, params: {
        id: reviews(:review_without_conclusion_and_without_findings).id
      }
    end

    assert_redirected_to reviews_url
  end

  test 'destroy with final review' do
    login
    assert_no_difference 'Review.count' do
      delete :destroy, params: { id: reviews(:current_review).id }
    end

    assert_redirected_to reviews_url
    assert_equal I18n.t('review.errors.can_not_be_destroyed'), flash.alert
  end

  test 'assignment type refresh' do
    login

    get :assignment_type_refresh, xhr: true, params: {
      user_id: users(:administrator).id
    }, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'plan item refresh' do
    login

    get :plan_item_refresh, xhr: true, params: {
      period_id: periods(:current_period).id,
      prefix: business_unit_types(:cycle).review_prefix
    }, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'plan item data' do
    login

    plan_item_data = nil

    get :plan_item_data, xhr: true, params: {
      id: plan_items(:current_plan_item_1).id
    }
    assert_response :success
    assert_nothing_raised do
      plan_item_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil plan_item_data
    assert_not_nil plan_item_data['scope']
    assert_not_nil plan_item_data['risk_exposure']
    assert_not_nil plan_item_data['business_unit_name']
    assert_not_nil plan_item_data['business_unit_type']
    assert_not_nil plan_item_data['business_unit_prefix']
  end

  test 'survey pdf' do
    login
    review = Review.find reviews(:current_review).id

    assert_nothing_raised do
      get :survey_pdf, params: { id: review.id }
    end

    assert_redirected_to review.relative_survey_pdf_path
  end

  test 'suggested findings' do
    login
    review = Review.find reviews(:current_review).id

    get :suggested_findings, params: { id: review.plan_item_id }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).count > 0
    assert assigns(:findings).all?(&:pending?)
    assert(
      assigns(:findings).all? do |f|
        f.review.plan_item.business_unit_id == review.plan_item.business_unit_id
      end
    )
    assert_template 'reviews/suggested_findings'
  end

  test 'suggested process control findings' do
    login
    process_control = process_controls :security_policy

    get :suggested_process_control_findings, params: { id: process_control.id }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).count > 0
    assert assigns(:findings).all?(&:pending?)
    assert(
      assigns(:findings).all? do |f|
        f.control_objective.process_control_id == process_control.id
      end
    )

    assert_template 'reviews/suggested_process_control_findings'
  end

  test 'past implemented audited findings' do
    review = reviews :current_review
    finding = findings :being_implemented_weakness_on_final

    login

    finding.update_column :state, Finding::STATUS[:implemented_audited]

    get :past_implemented_audited_findings, params: { id: review.plan_item_id }
    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).count > 0
    assert assigns(:findings).all?(&:implemented_audited?)
    assert(
      assigns(:findings).all? do |f|
        f.review.plan_item.business_unit_id == review.plan_item.business_unit_id
      end
    )
    assert_template 'reviews/past_implemented_audited_findings'
  end

  test 'download work papers' do
    login

    review = Review.find reviews(:current_review).id

    assert_nothing_raised do
      get :download_work_papers, params: { id: review.id }
    end

    assert_redirected_to review.relative_work_papers_zip_path
  end

  test 'estimated amount' do
    login
    get :estimated_amount, params: { id: plan_items(:past_plan_item_1).id }

    assert_response :success
    assert_template 'reviews/_estimated_amount'
  end

  test 'finished work papers' do
    review = reviews(:past_review) # should work even if it has final review

    login

    assert_difference 'review.versions.count' do
      patch :finished_work_papers, params: { id: review.id }
    end

    assert_redirected_to review_url(review)
    assert review.reload.work_papers_finished?
  end

  test 'supervised work papers' do
    review = reviews(:past_review) # should work even if it has final review

    login user: users(:supervisor)

    assert_difference 'review.versions.count' do
      patch :finished_work_papers, params: { id: review.id, revised: true }
    end

    assert_redirected_to review_url(review)
    assert review.reload.work_papers_revised?
  end

  test 'recode findings' do
    login

    patch :recode_findings, params: { id: reviews(:review_without_conclusion).id }

    assert_redirected_to review_url(reviews(:review_without_conclusion))
  end

  test 'recode findings by risk' do
    login

    patch :recode_weaknesses_by_risk, params: { id: reviews(:review_without_conclusion).id }

    assert_redirected_to review_url(reviews(:review_without_conclusion))
  end

  test 'recode weaknesses by control objective order' do
    login

    patch :recode_weaknesses_by_control_objective_order, params: { id: reviews(:review_without_conclusion).id }

    assert_redirected_to review_url(reviews(:review_without_conclusion))
  end

  test 'next identification number' do
    login

    get :next_identification_number, xhr: true, params: {
      prefix: 'TS',
      suffix: 2017
    }, as: :js

    assert_response :success
    assert_match /TS-001\/2017/, @response.body
  end

  test 'auto complete for control objectives' do
    login
    get :auto_complete_for_control_objective, xhr: true, params: {
      q: 'access'
    }, as: :json
    assert_response :success

    control_objectives = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, control_objectives.size
    assert(
      control_objectives.all? do |co|
        (co['label'] + co['informal']).match /access/i
      end
    )

    get :auto_complete_for_control_objective, xhr: true, params: {
      q: 'dependency'
    }, as: :json
    assert_response :success

    control_objectives = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, control_objectives.size
    assert(
      control_objectives.all? do |co|
        (co['label'] + co['informal']).match /dependency/i
      end
    )

    get :auto_complete_for_control_objective, xhr: true, params: {
      q: 'xyz'
    }, as: :json
    assert_response :success

    control_objectives = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, control_objectives.size # None
  end

  test 'auto complete for process controls' do
    login
    get :auto_complete_for_process_control, xhr: true, params: {
      q: 'sec'
    }, as: :json
    assert_response :success

    process_controls = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, process_controls.size
    assert(
      process_controls.all? do |pc|
        (pc['label'] + pc['informal']).match /sec/i
      end
    )

    get :auto_complete_for_process_control, xhr: true, params: {
      q: 'data'
    }, as: :json
    assert_response :success

    process_controls = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, process_controls.size
    assert(
      process_controls.all? do |pc|
        (pc['label'] + pc['informal']).match /data/i
      end
    )

    get :auto_complete_for_process_control, xhr: true, params: {
      q: 'xyz'
    }, as: :json
    assert_response :success

    process_controls = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, process_controls.size # None
  end

  test 'auto complete for finding relation' do
    login
    get :auto_complete_for_finding, xhr: true, params: { q: 'O001' }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    get :auto_complete_for_finding, xhr: true, params: { q: 'O001, 1 2 3' }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }

    get :auto_complete_for_finding, xhr: true, params: { q: 'x_none' }, as: :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, findings.size # Sin resultados
  end

  test 'auto complete for tagging' do
    login

    get :auto_complete_for_tagging, xhr: true, params: {
      q: 'high priority',
      kind: 'review'
    }, as: :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /high priority/i }

    get :auto_complete_for_tagging, xhr: true, params: {
      q: 'x_none',
      kind: 'finding'
    }, as: :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, tags.size # Sin resultados
  end

  test 'excluded control objectives' do
    login

    get :excluded_control_objectives, xhr: true, params: {
      id: reviews(:current_review).id
    }, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end
end
