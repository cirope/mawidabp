require 'test_helper'

# Pruebas para el controlador de informes
class ReviewsControllerTest < ActionController::TestCase
  fixtures :reviews, :plan_items, :periods, :control_objectives, :controls

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {id: reviews(:current_review).to_param}
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
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_not_equal 0, assigns(:reviews).size
    assert_template 'reviews/index'
  end

  test 'list reviews with search' do
    perform_auth
    get :index, search: {
      query: '1 2',
      columns: ['identification', 'project']
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 5, assigns(:reviews).size
    assert_template 'reviews/index'
  end

  test 'edit review when search match only one result' do
    perform_auth
    get :index, search: {
      query: '1 1',
      columns: ['identification', 'project']
    }
    assert_redirected_to review_url(reviews(:past_review))
    assert_not_nil assigns(:reviews)
    assert_equal 1, assigns(:reviews).size
  end

  test 'show review' do
    perform_auth
    get :show, id: reviews(:current_review).id
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/show'
  end

  test 'new review' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/new'
  end

  test 'clone review' do
    perform_auth
    review = Review.find reviews(:current_review).id

    get :new, clone_from: review.id
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
    perform_auth
    assert_difference ['Review.count', 'FindingReviewAssignment.count'] do
      # Se crean 2 con los datos y uno con 'procedure_control_subitem_ids'
      assert_difference 'FileModel.count' do
        assert_difference 'ReviewUserAssignment.count', 4 do
          post :create, {
            review: {
              identification: 'New Identification',
              description: 'New Description',
              survey: 'New survey',
              period_id: periods(:current_period).id,
              plan_item_id: plan_items(:past_plan_item_3).id,
              procedure_control_subitem_ids:
                [procedure_control_subitems(:procedure_control_subitem_bcra_A4609_1_1).id],
              file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
              },
              finding_review_assignments_attributes: [
                {
                  finding_id:
                    findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id.to_s
                }
              ],
              review_user_assignments_attributes: [
                {
                  assignment_type: ReviewUserAssignment::TYPES[:auditor],
                  user_id: users(:first_time_user).id
                }, {
                  assignment_type:
                    ReviewUserAssignment::TYPES[:supervisor],
                  user_id: users(:supervisor_user).id
                }, {
                  assignment_type: ReviewUserAssignment::TYPES[:manager],
                  user_id: users(:supervisor_second_user).id
                }, {
                  assignment_type: ReviewUserAssignment::TYPES[:audited],
                  user_id: users(:audited_user).id
                }
              ]
            }
          }
        end
      end
    end
  end

  test 'edit review' do
    perform_auth
    get :edit, id: reviews(:current_review).id
    assert_response :success
    assert_not_nil assigns(:review)
    assert_template 'reviews/edit'
  end

  test 'update review' do
    counts_array = ['Review.count', 'ControlObjectiveItem.count',
      'ReviewUserAssignment.count', 'FileModel.count', 'Control.count']
    perform_auth
    assert_no_difference counts_array do
      patch :update, {
        id: reviews(:review_with_conclusion).id,
        review: {
          identification: 'Updated Identification',
          description: 'Updated Description',
          period_id: periods(:current_period).id,
          plan_item_id: plan_items(:current_plan_item_2).id,
          review_user_assignments_attributes: [
            {
              id: review_user_assignments(:review_with_conclusion_bare_auditor).id,
              assignment_type: ReviewUserAssignment::TYPES[:auditor],
              user_id: users(:bare_user).id
            }
          ],
          control_objective_items_attributes: [
            {
              id: control_objective_items(
                :bcra_A4609_security_management_responsible_dependency_item_editable).id,
              order_number: 1
            }
          ]
        }
      }
    end

    control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item_editable).id)

    assert_redirected_to edit_review_url(reviews(:review_with_conclusion).id)
    assert_not_nil assigns(:review)
    assert_equal 'Updated Description', assigns(:review).description
  end

  test 'destroy review' do
    perform_auth
    assert_difference 'Review.count', -1 do
      delete :destroy, id: reviews(:review_without_conclusion_and_without_findings).id
    end

    assert_redirected_to reviews_url
  end

  test 'destroy with final review' do
    perform_auth
    assert_no_difference 'Review.count' do
      delete :destroy, id: reviews(:current_review).id
    end

    assert_redirected_to reviews_url
    assert_equal I18n.t('review.errors.can_not_be_destroyed'), flash.alert
  end

  test 'review data' do
    perform_auth

    review_data = nil

    xhr :get, :review_data, id: reviews(:current_review).id,
      format: 'json'
    assert_response :success
    assert_nothing_raised do
      review_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil review_data
    assert_not_nil review_data['score_text']
    assert_not_nil review_data['plan_item']
    assert_not_nil review_data['plan_item']['project']
    assert_not_nil review_data['business_unit']
    assert_not_nil review_data['business_unit']['name']
  end

  test 'plan item data' do
    perform_auth

    plan_item_data = nil

    xhr :get, :plan_item_data, id: plan_items(:current_plan_item_1).id
    assert_response :success
    assert_nothing_raised do
      plan_item_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil plan_item_data
    assert_not_nil plan_item_data['business_unit_name']
    assert_not_nil plan_item_data['business_unit_type']
  end

  test 'procedure control data' do
    perform_auth

    get :procedure_control_data,
      id: procedure_controls(:procedure_control_iso_27001).id
    assert_response :success
    assert_not_nil assigns(:procedure_control)
    assert_template 'procedure_controls/show'
  end

  test 'survey pdf' do
    perform_auth
    review = Review.find reviews(:current_review).id

    assert_nothing_raised do
      get :survey_pdf, id: review.id
    end

    assert_redirected_to review.relative_survey_pdf_path
  end

  test 'suggested findings' do
    perform_auth
    review = Review.find reviews(:current_review).id

    get :suggested_findings, id: review.plan_item_id
    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).size > 0
    assert assigns(:findings).all?(&:pending?)
    assert(
      assigns(:findings).all? do |f|
        f.review.plan_item.business_unit_id == review.plan_item.business_unit_id
      end
    )
    assert_template 'reviews/suggested_findings'
  end

  test 'download work papers' do
    perform_auth

    review = Review.find reviews(:current_review).id

    assert_nothing_raised do
      get :download_work_papers, id: review.id
    end

    assert_redirected_to review.relative_work_papers_zip_path
  end

  test 'estimated amount' do
    perform_auth
    get :estimated_amount, id: plan_items(:past_plan_item_1).id

    assert_response :success
    assert_template 'reviews/_estimated_amount'
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { q: 'admin', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Administrator
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :auto_complete_for_user, { q: 'blank', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size # Blank and Expired blank
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }

    post :auto_complete_for_user, { q: 'xyz', format: :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end

  test 'auto complete for procedure control subitem' do
    perform_auth
    get :auto_complete_for_procedure_control_subitem, {
      q: 'ges seg', period_id: periods(:past_period).id, format: :json
    }
    assert_response :success

    procedure_control_subitems = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, procedure_control_subitems.size # Gestión de la seguridad
    assert(
      procedure_control_subitems.all? do
        |pcs| (pcs['label'] + pcs['informal']).match /ges.*seg/i
      end
    )

    get :auto_complete_for_procedure_control_subitem, {
      q: 'depen', period_id: periods(:past_period).id, format: :json
    }
    assert_response :success

    procedure_control_subitems = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, procedure_control_subitems.size # Dependencia del área responsable
    assert(
      procedure_control_subitems.all? do
        |pcs| (pcs['label'] + pcs['informal']).match /depen/i
      end
    )

    get :auto_complete_for_procedure_control_subitem, {
      q: 'xyz', period_id: periods(:past_period).id, format: :json
    }
    assert_response :success

    procedure_control_subitems = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, procedure_control_subitems.size # None
  end

  test 'auto complete for finding relation' do
    perform_auth
    get :auto_complete_for_finding, { q: 'O001', format: :json }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    get :auto_complete_for_finding, { q: 'O001, 1 2 3', format: :json }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }

    get :auto_complete_for_finding, { q: 'x_none', format: :json }
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, findings.size # Sin resultados
  end
end
