require 'test_helper'

class WeaknessTemplatesControllerTest < ActionController::TestCase

  setup do
    @weakness_template = weakness_templates :security

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:weakness_templates)
  end

  test 'should get filtered index' do
    login
    get :index, params: {
      search: {
        query: 'sec',
        columns: ['title']
      }
    }
    assert_response :success
    assert_not_nil assigns(:weakness_templates)
    assert_equal 1, assigns(:weakness_templates).count
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create weakness_template' do
    counts = %w(
      WeaknessTemplate.count
      ControlObjectiveWeaknessTemplateRelation.count
    )

    assert_difference counts do
      post :create, params: {
        weakness_template: {
          title: 'New weakness template',
          description: 'New weakness template description',
          risk: WeaknessTemplate.risks_values.first,
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          control_objective_weakness_template_relations_attributes: [
            {
              control_objective_id: control_objectives(:impact_analysis).id
            }
          ]
        }
      }
    end

    assert_redirected_to weakness_template_url(assigns(:weakness_template))
  end

  test 'should show weakness_template' do
    get :show, params: { id: @weakness_template }

    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @weakness_template }

    assert_response :success
  end

  test 'should update weakness_template' do
    patch :update, params: {
      id: @weakness_template, weakness_template: { title: 'New title' }
    }

    assert_redirected_to weakness_template_url(assigns(:weakness_template))
  end

  test 'should destroy weakness_template' do
    assert_difference 'WeaknessTemplate.count', -1 do
      delete :destroy, params: { id: @weakness_template }
    end

    assert_redirected_to weakness_templates_url
  end
end
