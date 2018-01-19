require 'test_helper'

class RiskAssessmentsControllerTest < ActionController::TestCase

  setup do
    @risk_assessment = risk_assessments :sox_current

    login
  end

  teardown do
    Organization.current_id = nil
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:risk_assessments)
  end

  test 'should get filtered index' do
    get :index, params: {
      search: {
        query: 'sox',
        columns: ['name']
      }
    }
    assert_response :success
    assert_not_nil assigns(:risk_assessments)
    assert_equal 1, assigns(:risk_assessments).count
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create risk_assessment' do
    assert_difference 'RiskAssessment.count' do
      post :create, params: {
        risk_assessment: {
          name: 'New risk assessment',
          description: 'New risk assessment description',
          period_id: periods(:current_period).id,
          risk_assessment_template_id: risk_assessment_templates(:sox).id
        }
      }
    end

    assert_redirected_to risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should show risk_assessment' do
    get :show, params: { id: @risk_assessment }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_assessment }
    assert_response :success
  end

  test 'should update risk_assessment' do
    patch :update, params: {
      id: @risk_assessment, risk_assessment: { name: 'Updated name' }
    }

    assert_redirected_to risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should destroy risk_assessment' do
    assert_difference 'RiskAssessment.count', -1 do
      delete :destroy, params: { id: @risk_assessment }
    end

    assert_redirected_to risk_assessments_url
  end
end
