require 'test_helper'

# Pruebas para el controlador de items de objetivos de control
class ControlObjectiveItemsControllerTest < ActionController::TestCase
  fixtures :control_objective_items, :control_objectives, :reviews

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :show, :edit, :update, :destroy]
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

  test 'list control objective items' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert_select '#error_body', false
    assert_template 'control_objective_items/index'
  end

  test 'list control objective items with search' do
    perform_auth
    get :index, :search => {
      :query => 'seguridad',
      :columns => ['control_objective_text', 'review']
    }
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert_equal 4, assigns(:control_objectives).size
    assert(assigns(:control_objectives).all? do |coi|
      coi.control_objective_text.match(/seguridad/i)
    end)
    assert_select '#error_body', false
    assert_template 'control_objective_items/index'
  end

  test 'edit control objective item when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => 'dependencia y responsable',
      :columns => ['control_objective_text', 'review']
    }
    assert_redirected_to edit_control_objective_item_path(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item))
    assert_not_nil assigns(:control_objectives)
    assert_equal 1, assigns(:control_objectives).size
  end

  test 'show control_objective_item' do
    perform_auth
    get :show, :id => control_objective_items(:bcra_A4609_security_management_responsible_dependency_item).id
    assert_response :success
    assert_not_nil assigns(:control_objective_item)
    assert_select '#error_body', false
    assert_template 'control_objective_items/show'
  end

  test 'edit control_objective_item' do
    perform_auth
    get :edit, :id => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:control_objective_item)
    assert_select '#error_body', false
    assert_template 'control_objective_items/edit'
  end

  test 'update control_objective_item' do
    assert_no_difference ['ControlObjectiveItem.count', 'Control.count'] do
      assert_difference 'WorkPaper.count', 2 do
        perform_auth
        put :update, {
          :id => control_objective_items(
            :bcra_A4609_security_management_responsible_dependency_item_editable).id,
          :control_objective_item => {
            :control_objective_text => 'Updated text',
            :relevance =>
              get_test_parameter(:admin_control_objective_importances).last[1],
            :controls_attributes => {
              controls(:bcra_A4609_security_management_responsible_dependency_item_editable_control_1).id => {
                :id => controls(:bcra_A4609_security_management_responsible_dependency_item_editable_control_1).id,
                :control => 'Updated control',
                :effects => 'Updated effects',
                :design_tests => 'Updated design tests',
                :compliance_tests => 'Updated compliance tests'
              }
            },
            :pre_audit_qualification =>
              get_test_parameter(:admin_control_objective_qualifications).last[1],
            :post_audit_qualification =>
              get_test_parameter(:admin_control_objective_qualifications).last[1],
            :audit_date => 10.days.from_now.to_date,
            :auditor_comment => 'Updated comment',
            :control_objective_id =>
              control_objectives(:iso_27000_security_organization_4_1).id,
            :review_id => reviews(:review_with_conclusion).id,
            :pre_audit_work_papers_attributes => {
              :new_1 => {
                :name => 'New pre_workpaper name',
                :code => 'PTOC 20',
                :number_of_pages => '10',
                :description => 'New pre_workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :uploaded_data => ActionController::TestUploadedFile.new(
                    TEST_FILE, 'text/plain')
                }
              }
            },
            :post_audit_work_papers_attributes => {
              :new_1 => {
                :name => 'New post_workpaper name',
                :code => 'PTOC 21',
                :number_of_pages => '10',
                :description => 'New post_workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :uploaded_data => ActionController::TestUploadedFile.new(
                    TEST_FILE, 'text/plain')
                }
              }
            }
          }
        }
      end
    end
    
    assert_redirected_to edit_control_objective_item_path(
      control_objective_items(
        :bcra_A4609_security_management_responsible_dependency_item_editable))
    assert_not_nil assigns(:control_objective_item)
    assert_equal 'Updated text',
      assigns(:control_objective_item).control_objective_text
  end

  test 'destroy control_objective_item' do
    perform_auth
    assert_difference 'ControlObjectiveItem.count', -1 do
      delete :destroy, :id => control_objective_items(
        :bcra_A4609_data_proccessing_impact_analisys_item_editable).id
    end

    assert_redirected_to control_objective_items_path
  end
end