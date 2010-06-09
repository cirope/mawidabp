require 'test_helper'

# Pruebas para el controlador de procedimientos de control
class ProcedureControlsControllerTest < ActionController::TestCase
  fixtures :procedure_controls, :organizations, :periods

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index, :show, :new, :edit, :create, :update, :destroy]
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:notice]
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'list procedure controls' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:procedure_controls)
    assert_select '#error_body', false
    assert_template 'procedure_controls/index'
  end

  test 'show procedure control' do
    perform_auth
    get :show, :id => procedure_controls(:procedure_control_iso_27001).id
    assert_response :success
    assert_not_nil assigns(:procedure_control)
    assert_select '#error_body', false
    assert_template 'procedure_controls/show'
  end

  test 'new procedure control' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:procedure_control)
    assert_select '#error_body', false
    assert_template 'procedure_controls/new'
  end

  test 'create procedure control' do
    counts_array = ['ProcedureControl.count', 'ProcedureControlItem.count',
      'ProcedureControlSubitem.count']
    perform_auth
    assert_difference counts_array do
      post :create, {
        :procedure_control => {
          :period_id => periods(:current_period).id,
          :procedure_control_items_attributes => {
            :new_1 => {
              :aproach => get_test_parameter(:admin_aproach_types).first[1],
              :frequency => get_test_parameter(:admin_frequency_types).first[1],
              :process_control_id =>
                process_controls(:iso_27000_assets_control).id,
              :order => 1,
              :procedure_control_subitems_attributes => {
                :new_1 => {
                  :control_objective_text => 'New control objective text',
                  :main_procedures => 'New main procedure',
                  :design_tests => 'New design tests',
                  :compliance_tests => 'New compliance tests',
                  :effects => 'New effects',
                  :risk =>
                    get_test_parameter(:admin_control_objective_risk_levels).first[1],
                  :control_objective_id =>
                    control_objectives(:iso_27000_security_organization_4_1).id,
                  :order => 1,
                }
              }
            }
          }
        }
      }
    end
  end

  test 'edit procedure control' do
    perform_auth
    get :edit, :id => procedure_controls(:procedure_control_iso_27001).id
    assert_response :success
    assert_not_nil assigns(:procedure_control)
    assert_select '#error_body', false
    assert_template 'procedure_controls/edit'
  end

  test 'update procedure control' do
    counts_array = ['ProcedureControl.count', 'ProcedureControlItem.count',
      'ProcedureControlSubitem.count']

    assert_no_difference counts_array do
      perform_auth
      put :update, {
        :id => procedure_controls(:procedure_control_iso_27001).id,
        :procedure_control => {
          :period_id => periods(:current_period).id,
          :procedure_control_items_attributes => {
            procedure_control_items(:procedure_control_item_iso_27001_2).id => {
              :id =>
                procedure_control_items(:procedure_control_item_iso_27001_2).id,
              :aproach => get_test_parameter(:admin_aproach_types).first[1],
              :frequency => get_test_parameter(:admin_frequency_types).first[1],
              :process_control_id =>
                process_controls(:iso_27000_assets_control).id,
              :order => 1,
              :procedure_control_subitems_attributes => {
                procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id => {
                  :id => procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id,
                  :main_procedures => 'Updated main procedure',
                  :design_tests => 'Updated design tests',
                  :compliance_tests => 'Updated compliance tests',
                  :effects => 'Updated effects',
                  :risk =>
                    get_test_parameter(:admin_control_objective_risk_levels).first[1],
                  :control_objective_id =>
                    control_objectives(:iso_27000_security_organization_4_1).id,
                  :order => 1,
                }
              }
            }
          }
        }
      }
    end

    procedure_control_subitem = ProcedureControlSubitem.find(
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id)

    assert_redirected_to edit_procedure_control_path(
      procedure_controls(:procedure_control_iso_27001).id)
    assert_not_nil assigns(:procedure_control)
    assert_equal 'Updated main procedure',
      procedure_control_subitem.main_procedures
  end

  test 'destroy procedure control' do
    perform_auth
    assert_difference 'ProcedureControl.count', -1 do
      delete :destroy, :id => procedure_controls(:procedure_control_iso_27001).id
    end

    assert_redirected_to procedure_controls_path
  end

  test 'export to pdf' do
    perform_auth

    procedure_control = ProcedureControl.find(
      procedure_controls(:procedure_control_iso_27001).id)

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :id => procedure_control.id
    end
    
    assert_redirected_to PDF::Writer.relative_path('procedure_control.pdf',
      'procedure_controls', procedure_control.id)
  end

  test 'get control objectives' do
    perform_auth
    xhr :get, :get_control_objectives, {:process_control =>
        process_controls(:iso_27000_security_policy).id}
    assert_response :success
    process_controls = ActiveSupport::JSON.decode(@response.body)
    assert !process_controls.empty?
    assert process_controls.any? { |co|
      co.first == control_objectives(:iso_27000_security_policy_3_1).name
    }
  end

  test 'get control objective' do
    perform_auth
    xhr :get, :get_control_objective, {:control_objective =>
        control_objectives(:iso_27000_security_policy_3_1).id}
    assert_response :success
    control_objective = ActiveSupport::JSON.decode(@response.body)
    assert_equal control_objectives(:iso_27000_security_policy_3_1).name,
      control_objective['control_objective']['name']
    assert_equal control_objectives(:iso_27000_security_policy_3_1).
      controls.first.control,
      control_objective['control_objective']['controls'][0]['control']
  end

  test 'get procedure controls' do
    perform_auth
    xhr :get, :get_process_controls, {:best_practice =>
        best_practices(:iso_27001).id}
    assert_response :success
    process_controls = ActiveSupport::JSON.decode(@response.body)
    assert !process_controls.empty?
    assert process_controls.any? { |co|
      co.first == process_controls(:iso_27000_security_policy).name
    }
  end
end