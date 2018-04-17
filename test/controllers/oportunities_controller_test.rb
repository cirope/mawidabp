require 'test_helper'

# Pruebas para el controlador de oportunidades
class OportunitiesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  setup do
    skip if HIDE_OPORTUNITIES
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      :params => {
        :id => findings(:confirmed_oportunity).to_param
      }
    }
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
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list oportunities' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:oportunities)
    assert_template 'oportunities/index'
  end

  test 'list oportunities with search and sort' do
    login
    get :index, :params => {
      :search => {
        :query => '1 2 4',
        :columns => ['title', 'review'],
        :order => 'review'
      }
    }

    assert_response :success
    assert_not_nil assigns(:oportunities)
    assert_equal 2, assigns(:oportunities).count
    assert(assigns(:oportunities).all? do |o|
      o.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:oportunities).map {|o| o.review.identification}.sort,
      assigns(:oportunities).map {|o| o.review.identification}
    assert_template 'oportunities/index'
  end

  test 'show oportunity' do
    login
    get :show, :params => {
      :id => findings(:confirmed_oportunity).id
    }
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_template 'oportunities/show'
  end

  test 'show oportunity in json' do
    oportunity = findings :confirmed_oportunity

    login
    get :show, :params => {
      :completed => 'incomplete',
      :id => oportunity.id
    }, :as => :json
    assert_response :success
    assert_not_nil assigns(:oportunity)

    decoded_oportunity = ActiveSupport::JSON.decode @response.body

    assert_equal oportunity.id, decoded_oportunity['id']
  end

  test 'new oportunity' do
    login
    get :new, :params => {
      :control_objective_item => control_objective_items(:management_dependency_item_editable).id
    }
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_template 'oportunities/new'
  end

  test 'create oportunity' do
    counts_array = [
      'Oportunity.count',
      'WorkPaper.count',
      'BusinessUnitFinding.count',
      'FindingRelation.count',
      'Tagging.count'
    ]

    login
    assert_difference counts_array do
      post :create, :params => {
        :oportunity => {
          :control_objective_item_id =>
            control_objective_items(:impact_analysis_item_editable).id,
          :review_code => 'OM020',
          :title => 'Title',
          :description => 'New description',
          :answer => 'New answer',
          :audit_comments => 'New audit comments',
          :origination_date => 1.day.ago.to_date.to_s(:db),
          :state => Finding::STATUS[:being_implemented],
          :business_unit_ids => [business_units(:business_unit_three).id],
          :finding_user_assignments_attributes => [
            {
              :user_id => users(:bare).id, :process_owner => '0'
            },
            {
              :user_id => users(:audited).id, :process_owner => '1'
            },
            {
              :user_id => users(:auditor).id, :process_owner => '0'
            },
            {
              :user_id => users(:manager).id, :process_owner => '0'
            },
            {
              :user_id => users(:supervisor).id, :process_owner => '0'
            },
            {
              :user_id => users(:administrator).id, :process_owner => '0'
            }
          ],
          :work_papers_attributes => [
            {
              :name => 'New workpaper name',
              :code => 'PTOM 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :file_model_attributes => {:file => Rack::Test::UploadedFile.new(
                  TEST_FILE_FULL_PATH, 'text/plain')
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
          ]
        }
      }
    end
  end

  test 'edit oportunity' do
    login
    get :edit, :params => {
      :id => findings(:confirmed_oportunity).id
    }
    assert_response :success
    assert_not_nil assigns(:oportunity)
    assert_template 'oportunities/edit'
  end

  test 'update oportunity' do
    login
    assert_no_difference 'Oportunity.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        patch :update, :params => {
          :id => findings(:confirmed_oportunity).id,
          :oportunity => {
            :control_objective_item_id =>
              control_objective_items(:impact_analysis_item).id,
            :review_code => 'OM020',
            :title => 'Title',
            :description => 'Updated description',
            :answer => 'Updated answer',
            :audit_comments => 'Updated audit comments',
            :state => Finding::STATUS[:confirmed],
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :solution_date => '',
            :finding_user_assignments_attributes => [
              {
                :id => finding_user_assignments(:confirmed_oportunity_bare).id,
                :user_id => users(:bare).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:confirmed_oportunity_audited).id,
                :user_id => users(:audited).id,
                :process_owner => '1'
              },
              {
                :id => finding_user_assignments(:confirmed_oportunity_auditor).id,
                :user_id => users(:auditor).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:confirmed_oportunity_manager).id,
                :user_id => users(:manager).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:confirmed_oportunity_supervisor).id,
                :user_id => users(:supervisor).id,
                :process_owner => '0'
              },
              {
                :id => finding_user_assignments(:confirmed_oportunity_administrator).id,
                :user_id => users(:administrator).id,
                :process_owner => '0'
              }
            ],
            :work_papers_attributes => [
              {
                :name => 'New workpaper name',
                :code => 'PTOM 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(
                    TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            ],
            :finding_relations_attributes => [
              {
                :description => 'Duplicated',
                :related_finding_id => findings(:unanswered_weakness).id
              }
            ]
          }
        }
      end
    end

    assert_not_nil assigns(:oportunity)
    assert_redirected_to edit_oportunity_url(assigns(:oportunity))
    assert_equal 'OM020', assigns(:oportunity).review_code
  end

  test 'undo reiteration' do
    login
    review = Review.find(reviews(:review_with_conclusion).id)

    assert_difference 'review.finding_review_assignments.count' do
      review.finding_review_assignments.create(
        :finding_id => findings(:being_implemented_weakness).id
      )
    end

    oportunity = Finding.find(findings(:being_implemented_oportunity).id)
    repeated_of = Finding.find(findings(:being_implemented_weakness).id)
    repeated_of_original_state = repeated_of.state

    assert !repeated_of.repeated?
    assert oportunity.update(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert oportunity.reload.repeated_of

    patch :undo_reiteration, :params => { :id => oportunity.to_param }
    assert_redirected_to edit_oportunity_url(oportunity)

    assert !repeated_of.reload.repeated?
    assert_nil oportunity.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'auto complete for finding relation' do
    finding = Finding.find(findings(:being_implemented_oportunity).id)

    login
    get :auto_complete_for_finding_relation, :params => {
      :q => 'O001',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }, :as => :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, findings.size
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    finding = Finding.find(findings(:notify_oportunity).id)

    get :auto_complete_for_finding_relation, :params => {
      :q => 'O001',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }, :as => :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, findings.size # Se excluye la observación O01 que no tiene informe definitivo
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001/i }

    get :auto_complete_for_finding_relation, :params => {
      :completed => 'incomplete',
      :q => 'O001, 1 2 3',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }, :as => :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, findings.size # Solo O01 del informe 1 2 3
    assert findings.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }

    get :auto_complete_for_finding_relation, :params => {
      :q => 'x_none',
      :finding_id => finding.id,
      :review_id => finding.review.id
    }, :as => :json
    assert_response :success

    findings = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, findings.size # Sin resultados
  end

  test 'auto complete for tagging' do
    login

    get :auto_complete_for_tagging, :params => {
      :q => 'impor',
      :kind => 'finding'
    }, :as => :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /impor/i }

    get :auto_complete_for_tagging, :params => {
      :q => 'x_none',
      :kind => 'finding'
    }, :as => :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, tags.size # Sin resultados
  end

  test 'auto complete for control objective item' do
    login
    get :auto_complete_for_control_objective_item, :params => {
      :q => 'dependencia',
      :review_id => reviews(:review_with_conclusion).id
    }, :as => :json
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, cois.size # management_dependency_item_editable
    assert cois.all? { |f| (f['label'] + f['informal']).match /dependencia/i }
    assert_equal(
      control_objective_items(:management_dependency_item_editable).id,
      cois.first['id']
    )

    get :auto_complete_for_control_objective_item, :params => {
      :q => 'x_none',
      :review_id => reviews(:review_with_conclusion).id
    }, :as => :json
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, cois.size # Sin resultados
  end
end
