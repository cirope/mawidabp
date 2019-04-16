require 'test_helper'

class RiskAssessmentTemplatesControllerTest < ActionController::TestCase

  setup do
    @risk_assessment_template = risk_assessment_templates :sox

    login
    set_organization
  end

  teardown do
    unset_organization
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:risk_assessment_templates)
  end

  test 'should get filtered index' do
    get :index, params: {
      search: {
        query: 'sox',
        columns: ['name']
      }
    }
    assert_response :success
    assert_not_nil assigns(:risk_assessment_templates)
    assert_equal 1, assigns(:risk_assessment_templates).count
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should get new with clone from' do
    get :new, params: { clone_from: @risk_assessment_template.id }
    assert_response :success
  end

  test 'should create risk_assessment_template' do
    counts = %w(RiskAssessmentTemplate.count RiskAssessmentWeight.count)

    assert_difference counts do
      post :create, params: {
        risk_assessment_template: {
          name: 'New',
          description: 'New risk template',
          risk_assessment_weights_attributes: [
            {
              name: 'New attribute',
              description: 'Some new attribute',
              weight: 80
            }
          ]
        }
      }
    end

    assert_redirected_to risk_assessment_template_url(assigns(:risk_assessment_template))
  end

  test 'should show risk_assessment_template' do
    get :show, params: { id: @risk_assessment_template }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_assessment_template }
    assert_response :success
  end

  test 'should update risk_assessment_template' do
    patch :update, params: {
      id: @risk_assessment_template, risk_assessment_template: {
        name: 'New name'
      }
    }
    assert_redirected_to risk_assessment_template_url(assigns(:risk_assessment_template))
  end

  test 'should destroy risk_assessment_template' do
    counts = %w(RiskAssessmentTemplate.count RiskAssessmentWeight.count)

    @risk_assessment_template.risk_assessments.destroy_all

    assert_difference counts, -1 do
      delete :destroy, params: { id: @risk_assessment_template }
    end

    assert_redirected_to risk_assessment_templates_url
  end
end
