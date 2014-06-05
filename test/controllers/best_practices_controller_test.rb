require 'test_helper'

class BestPracticesControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'list best practices' do
    get :index
    assert_response :success
    assert_not_nil assigns(:best_practices)
    assert_template 'best_practices/index'
  end

  test 'show best practice' do
    get :show, :id => best_practices(:iso_27001).id
    assert_response :success
    assert_not_nil assigns(:best_practice)
    assert_template 'best_practices/show'
  end

  test 'new best practice' do
    get :new
    assert_response :success
    assert_not_nil assigns(:best_practice)
    assert_template 'best_practices/new'
  end

  test 'create best_practice' do
    counts_array = ['BestPractice.count', 'ProcessControl.count',
      'ControlObjective.count', 'Control.count']
    assert_difference counts_array, 4 do
      post :create, {
        :best_practice => {
          :name => 'new_best_practice 1',
          :description => 'New description 1',
          :process_controls_attributes => [
            {
              :name => 'new process control',
              :order => 1,
              :control_objectives_attributes => [
                {
                  :name => 'new control objective 1 1',
                  :control_attributes => {
                    :control => 'new control 1 1',
                    :effects => 'new effects 1 1',
                    :design_tests => 'new design tests 1 1',
                    :compliance_tests => 'new compliance tests 1 1',
                    :sustantive_tests => 'new sustantive tests 1 1'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 1
                },
                {
                  :name => 'new control objective 1 2',
                  :control_attributes => {
                    :control => 'new control 1 2',
                    :effects => 'new effects 1 2',
                    :design_tests => 'new design tests 1 2',
                    :compliance_tests => 'new compliance tests 1 2',
                    :sustantive_tests => 'new sustantive tests 1 2'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 2
                }
              ]
            },
            {
              :name => 'new process control 2',
              :order => 2,
              :control_objectives_attributes => [
                {
                  :name => 'new control objective 2 1',
                  :control_attributes => {
                    :control => 'new control 2 1',
                    :effects => 'new effects 2 1',
                    :design_tests => 'new design tests 2 1',
                    :compliance_tests => 'new compliance tests 2 1',
                    :sustantive_tests => 'new sustantive tests 2 1'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 1
                },
                {
                  :name => 'new control objective 2 2',
                  :control_attributes => {
                    :control => 'new control 2 2',
                    :effects => 'new effects 2 2',
                    :design_tests => 'new design tests 2 2',
                    :compliance_tests => 'new compliance tests 2 2',
                    :sustantive_tests => 'new sustantive tests 2 2'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 2
                }
              ]
            }
          ]
        }
      }

      post :create, {
        :best_practice => {
          :name => 'new_best_practice 2',
          :description => 'New description 2',
          :process_controls_attributes => [
            {
              :name => 'new process control 3',
              :order => 1
            },
            {
              :name => 'new process control 4',
              :order => 2
            }
          ]
        }
      }

      post :create, {
        :best_practice => {
          :name => 'new_best_practice 3',
          :description => 'New description 3'
        }
      }

      post :create, {
        :best_practice => {
          :name => 'new_best_practice 4',
          :description => 'New description 4'
        }
      }
    end
  end

  test 'edit best practice' do
    get :edit, :id => best_practices(:iso_27001).id
    assert_response :success
    assert_not_nil assigns(:best_practice)
    assert_template 'best_practices/edit'
  end

  test 'update best practice' do
    counts_array = ['BestPractice.count', 'ProcessControl.count',
      'ControlObjective.count', 'Control.count']
    assert_no_difference counts_array do
      patch :update, {
        :id => best_practices(:iso_27001).id,
        :best_practice => {
          :name => 'updated_best_practice',
          :description => 'Updated description 1',
          :process_controls_attributes => [
            {
              :id => process_controls(:iso_27000_security_policy).id,
              :name => 'updated process control',
              :order => 1,
              :control_objectives_attributes => [
                {
                  :id => control_objectives(
                    :iso_27000_security_organization_4_1).id,
                  :name => 'updated control objective 1 1',
                  :control_attributes => {
                    :id => controls(:iso_27000_security_organization_4_1_control_1).id,
                    :control => 'updated control 1 1',
                    :effects => 'updated effects 1 1',
                    :design_tests => 'new design tests 1 1',
                    :compliance_tests => 'updated compliance tests 1 1',
                    :sustantive_tests => 'updated sustantive tests 1 1'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 1
                },
                {
                  :id => control_objectives(
                    :iso_27000_security_organization_4_2).id,
                  :name => 'updated control objective 1 2',
                  :control_attributes => {
                    :id => controls(:iso_27000_security_organization_4_2_control_1).id,
                    :control => 'updated control 1 2',
                    :effects => 'updated effects 1 2',
                    :design_tests => 'new design tests 1 2',
                    :compliance_tests => 'updated compliance_tests 1 2',
                    :sustantive_tests => 'updated sustantive_tests 1 2'
                  },
                  :relevance => ControlObjective.relevances_values.first,
                  :risk => ControlObjective.risks_values.first,
                  :order => 2
                }
              ]
            }
          ]
        }
      }
    end

    assert_redirected_to edit_best_practice_url(best_practices(:iso_27001).id)
    assert_not_nil assigns(:best_practice)
    assert_equal 'updated_best_practice', assigns(:best_practice).name
    assert_equal 'updated process control', ProcessControl.find(
      process_controls(:iso_27000_security_policy).id).name
    assert_equal 'updated control objective 1 1',
      ControlObjective.find(control_objectives(
        :iso_27000_security_organization_4_1).id).name
    assert_equal 'updated control 1 1', Control.find(
      controls(:iso_27000_security_organization_4_1_control_1).id).control
  end

  test 'destroy best_practice' do
    assert_difference 'BestPractice.count', -1 do
      delete :destroy, :id => best_practices(:useless_best_practice).id
    end

    assert_redirected_to best_practices_url
  end
end
