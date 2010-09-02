require 'test_helper'

# Pruebas para el controlador de informes
class ReviewsControllerTest < ActionController::TestCase
  fixtures :reviews, :plan_items, :periods, :control_objectives, :controls

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :show, :new, :edit, :create, :update, :destroy,
      :reviews_for_period]
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:alert]
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list reviews' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_not_equal 0, assigns(:reviews).size
    assert_select '#error_body', false
    assert_template 'reviews/index'
  end

  test 'list reviews with search' do
    perform_auth
    get :index, :search => {
      :query => '1 2',
      :columns => ['identification', 'project']
    }
    assert_response :success
    assert_not_nil assigns(:reviews)
    assert_equal 3, assigns(:reviews).size
    assert_select '#error_body', false
    assert_template 'reviews/index'
  end

  test 'edit review when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 1',
      :columns => ['identification', 'project']
    }
    assert_redirected_to edit_review_path(reviews(:past_review))
    assert_not_nil assigns(:reviews)
    assert_equal 1, assigns(:reviews).size
  end

  test 'show review' do
    perform_auth
    get :show, :id => reviews(:current_review).id
    assert_response :success
    assert_not_nil assigns(:review)
    assert_select '#error_body', false
    assert_template 'reviews/show'
  end

  test 'new review' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:review)
    assert_select '#error_body', false
    assert_template 'reviews/new'
  end

  test 'clone review' do
    perform_auth
    review = Review.find reviews(:current_review).id

    get :new, :clone_from => review.id
    assert_response :success
    assert_not_nil assigns(:review)
    assert review.control_objective_items.size > 0
    assert_equal review.control_objective_items.size,
      assigns(:review).control_objective_items.size
    assert review.review_user_assignments.size > 0
    assert_equal review.review_user_assignments.size,
      assigns(:review).review_user_assignments.size
    assert_select '#error_body', false
    assert_template 'reviews/new'
  end

  test 'create review' do
    perform_auth
    assert_difference 'Review.count' do
      # Se crean 2 con los datos y uno con 'procedure_control_subitem_ids'
      assert_difference ['ControlObjectiveItem.count', 'Control.count'], 3 do
        assert_difference 'WorkPaper.count', 4 do
          assert_difference 'FileModel.count', 5 do
            assert_difference 'ReviewUserAssignment.count', 4 do
              post :create, {
                :review => {
                  :identification => 'New Identification',
                  :description => 'New Description',
                  :survey => 'New survey',
                  :period_id => periods(:current_period).id,
                  :plan_item_id => plan_items(:past_plan_item_3).id,
                  :procedure_control_subitem_ids =>
                    [procedure_control_subitems(:procedure_control_subitem_bcra_A4609_1_1).id],
                  :file_model_attributes => {
                    :uploaded_data => ActionDispatch::Http::UploadedFile.new(
                      TEST_FILE, 'text/plain')
                  },
                  :review_user_assignments_attributes => {
                    :new_1 => {
                      :assignment_type => ReviewUserAssignment::TYPES[:auditor],
                      :user => users(:first_time_user)
                    },
                    :new_2 => {
                      :assignment_type =>
                        ReviewUserAssignment::TYPES[:supervisor],
                      :user => users(:supervisor_user)
                    },
                    :new_3 => {
                      :assignment_type => ReviewUserAssignment::TYPES[:manager],
                      :user => users(:manager_user)
                    },
                    :new_4 => {
                      :assignment_type => ReviewUserAssignment::TYPES[:audited],
                      :user => users(:audited_user)
                    }
                  },
                  :control_objective_items_attributes => {
                    :new_1 => {
                      :control_objective_text => 'New text',
                      :controls_attributes => {
                        :new_1 => {
                          :control => 'New control',
                          :effects => 'New effects',
                          :design_tests => 'New design tests',
                          :compliance_tests => 'New compliance tests'
                        }
                      },
                      :relevance => get_test_parameter(
                        :admin_control_objective_importances).last[1],
                      :pre_audit_qualification => get_test_parameter(
                        :admin_control_objective_qualifications).last[1],
                      :post_audit_qualification => get_test_parameter(
                        :admin_control_objective_qualifications).last[1],
                      :audit_date => Time.now.to_date,
                      :auditor_comment => 'New comment',
                      :control_objective_id => control_objectives(
                        :iso_27000_security_organization_4_1).id,
                      :pre_audit_work_papers_attributes => {
                        :new_1 => {
                          :name => 'New pre_workpaper name',
                          :code => 'PTOC 20',
                          :number_of_pages => '10',
                          :description => 'New pre_workpaper description',
                          :organization_id =>
                            organizations(:default_organization).id,
                          :file_model_attributes => {
                            :uploaded_data =>
                              ActionDispatch::Http::UploadedFile.new(
                              TEST_FILE)
                          }
                        }
                      },
                      :post_audit_work_papers_attributes => {
                        :new_1 => {
                          :name => 'New post_workpaper name',
                          :code => 'PTOC 21',
                          :number_of_pages => '10',
                          :description => 'New post_workpaper description',
                          :organization_id =>
                            organizations(:default_organization).id,
                          :file_model_attributes => {
                            :uploaded_data =>
                              ActionDispatch::Http::UploadedFile.new(
                              TEST_FILE)
                          }
                        }
                      }
                    },
                    :new_2 => {
                      :control_objective_text => 'New text',
                      :controls_attributes => {
                        :new_1 => {
                          :control => 'New control',
                          :effects => 'New effects',
                          :design_tests => 'New design tests',
                          :compliance_tests => 'New compliance tests'
                        }
                      },
                      :relevance => get_test_parameter(
                        :admin_control_objective_importances).last[1],
                      :pre_audit_qualification => get_test_parameter(
                        :admin_control_objective_qualifications).last[1],
                      :post_audit_qualification => get_test_parameter(
                        :admin_control_objective_qualifications).last[1],
                      :audit_date => Time.now.to_date,
                      :auditor_comment => 'New comment',
                      :control_objective_id => control_objectives(
                        :iso_27000_security_organization_4_2).id,
                      :pre_audit_work_papers_attributes => {
                        :new_1 => {
                          :name => 'New pre_workpaper name',
                          :code => 'PTOC 22',
                          :number_of_pages => '10',
                          :description => 'New pre_workpaper description',
                          :organization_id =>
                            organizations(:default_organization).id,
                          :file_model_attributes => {
                            :uploaded_data =>
                              ActionDispatch::Http::UploadedFile.new(
                              TEST_FILE)
                          }
                        }
                      },
                      :post_audit_work_papers_attributes => {
                        :new_1 => {
                          :name => 'New post_workpaper name',
                          :code => 'PTOC 23',
                          :number_of_pages => '10',
                          :description => 'New post_workpaper description',
                          :organization_id =>
                            organizations(:default_organization).id,
                          :file_model_attributes => {
                            :uploaded_data =>
                              ActionDispatch::Http::UploadedFile.new(
                              TEST_FILE)
                          }
                        }
                      }
                    }
                  }
                }
              }
            end
          end
        end
      end
    end
  end

  test 'edit review' do
    perform_auth
    get :edit, :id => reviews(:current_review).id
    assert_response :success
    assert_not_nil assigns(:review)
    assert_select '#error_body', false
    assert_template 'reviews/edit'
  end

  test 'update review' do
    counts_array = ['Review.count', 'ControlObjectiveItem.count',
      'ReviewUserAssignment.count', 'FileModel.count', 'Control.count']
    perform_auth
    assert_no_difference counts_array do
      put :update, {
        :id => reviews(:review_with_conclusion).id,
        :review => {
          :identification => 'Updated Identification',
          :description => 'Updated Description',
          :period_id => periods(:current_period).id,
          :plan_item_id => plan_items(:current_plan_item_2).id,
          :review_user_assignments_attributes => {
            review_user_assignments(:current_review_auditor).id => {
              :id => review_user_assignments(:current_review_auditor).id,
              :assignment_type => ReviewUserAssignment::TYPES[:auditor],
              :user => users(:bare_user)
            }
          },
          :control_objective_items_attributes => {
            control_objective_items(
              :bcra_A4609_security_management_responsible_dependency_item_editable).id => {
              :id => control_objective_items(
                :bcra_A4609_security_management_responsible_dependency_item_editable).id,
              :control_objective_text => 'Updated text',
              :controls_attributes => {
                controls(:bcra_A4609_security_management_responsible_dependency_item_editable_control_1).id => {
                  :id => controls(:bcra_A4609_security_management_responsible_dependency_item_editable_control_1).id,
                  :control => 'Updated control',
                  :effects => 'Updated effects',
                  :design_tests => 'Updated design tests',
                  :compliance_tests => 'Updated compliance tests'
                }
              },
              :relevance => get_test_parameter(
                :admin_control_objective_importances).last[1],
              :pre_audit_qualification => get_test_parameter(
                :admin_control_objective_qualifications).last[1],
              :post_audit_qualification => get_test_parameter(
                :admin_control_objective_qualifications).last[1],
              :audit_date => Time.now.to_date,
              :auditor_comment => 'Updated comment',
              :control_objective_id =>
                control_objectives(:iso_27000_security_organization_4_1).id
            }
          }
        }
      }
    end

    control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item_editable).id)

    assert_redirected_to edit_review_path(reviews(:review_with_conclusion).id)
    assert_not_nil assigns(:review)
    assert_equal 'Updated Description', assigns(:review).description
    assert_equal 'Updated text', control_objective_item.control_objective_text
  end

  test 'destroy review' do
    perform_auth
    assert_difference 'Review.count', -1 do
      delete :destroy, :id => reviews(:review_with_conclusion).id
    end

    assert_redirected_to reviews_path
  end

  test 'destroy with final review' do
    perform_auth
    assert_no_difference 'Review.count' do
      delete :destroy, :id => reviews(:current_review).id
    end

    assert_redirected_to reviews_path
    assert_equal I18n.t(:'review.errors.can_not_be_destroyed'), flash[:alert]
  end

  test 'review data' do
    perform_auth

    review_data = nil
    
    xhr :get, :review_data, :id => reviews(:current_review).id,
      :format => 'json'
    assert_response :success
    assert_nothing_raised(Exception) do
      review_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil review_data
    assert_not_nil review_data['review']
    assert_not_nil review_data['review']['score_text']
    assert_not_nil review_data['review']['plan_item']
    assert_not_nil review_data['review']['plan_item']['project']
    assert_not_nil review_data['review']['business_unit']
    assert_not_nil review_data['review']['business_unit']['name']
  end

  test 'plan item data' do
    perform_auth

    plan_item_data = nil

    xhr :get, :plan_item_data, :id => plan_items(:current_plan_item_1).id
    assert_response :success
    assert_nothing_raised(Exception) do
      plan_item_data = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil plan_item_data
    assert_not_nil plan_item_data['business_unit_name']
    assert_not_nil plan_item_data['business_unit_type']
  end

  test 'procedure control data' do
    perform_auth

    get :procedure_control_data,
      :id => procedure_controls(:procedure_control_iso_27001).id
    assert_response :success
    assert_not_nil assigns(:procedure_control)
    assert_select '#error_body', false
    assert_template 'procedure_controls/show'
  end

  test 'survey pdf' do
    perform_auth
    review = Review.find reviews(:current_review).id

    assert_nothing_raised(Exception) do
      get :survey_pdf, :id => review.id
    end

    assert_redirected_to review.relative_survey_pdf_path
  end

  test 'download work papers' do
    perform_auth

    review = Review.find reviews(:current_review).id

    assert_nothing_raised(Exception) do
      get :download_work_papers, :id => review.id
    end

    assert_redirected_to review.relative_work_papers_zip_path
  end

  test 'estimated amount' do
    perform_auth
    get :estimated_amount, :id => plan_items(:past_plan_item_1).id

    assert_response :success
    assert_select '#error_body', false
    assert_template 'reviews/_estimated_amount'
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'admin' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Administrator
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'blank' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size # Blank and Expired blank
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'xyz' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # None
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_user'
  end

  test 'auto complete for procedure control subitem' do
    perform_auth
    post :auto_complete_for_procedure_control_subitem, {
      :procedure_control_subitem_data => 'ges seg',
      :period_id => periods(:past_period).id
    }
    assert_response :success
    assert_not_nil assigns(:procedure_control_subitems)
    assert_equal 2, assigns(:procedure_control_subitems).size # Gestión de la seguridad
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_procedure_control_subitem'

    post :auto_complete_for_procedure_control_subitem, {
      :procedure_control_subitem_data => 'depen',
      :period_id => periods(:past_period).id
    }
    assert_response :success
    assert_not_nil assigns(:procedure_control_subitems)
    assert_equal 1, assigns(:procedure_control_subitems).size # Dependencia del área responsable
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_procedure_control_subitem'

    post :auto_complete_for_procedure_control_subitem, {
      :procedure_control_subitem_data => 'xyz',
      :period_id => periods(:past_period).id
    }
    assert_response :success
    assert_not_nil assigns(:procedure_control_subitems)
    assert_equal 0, assigns(:procedure_control_subitems).size # None
    assert_select '#error_body', false
    assert_template 'reviews/auto_complete_for_procedure_control_subitem'
  end
end