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

  test 'should create risk assessment' do
    counts = [
      'RiskAssessment.count',
      'RiskAssessmentItem.count',
      'RiskWeight.count'
    ]

    assert_difference counts do
      post :create, params: {
        risk_assessment: {
          name: 'New risk assessment',
          description: 'New risk assessment description',
          period_id: periods(:current_period).id,
          risk_assessment_template_id: risk_assessment_templates(:sox).id,
          risk_assessment_items_attributes: [
            {
              order: 1,
              name: 'New risk assessment item',
              business_unit_id: business_units(:business_unit_one).id,
              risk: 100,
              risk_weights_attributes: [
                {
                  value: RiskWeight.risks_values.last,
                  weight: 100,
                  risk_assessment_weight_id: risk_assessment_weights(:sox_404).id
                }
              ]
            }
          ]
        }
      }
    end

    assert_redirected_to edit_risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should show risk assessment' do
    get :show, params: { id: @risk_assessment }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_assessment }
    assert_response :success
  end

  test 'should update risk assessment' do
    patch :update, params: {
      id: @risk_assessment, risk_assessment: { name: 'Updated name' }
    }

    assert_redirected_to edit_risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should destroy risk assessment' do
    assert_difference 'RiskAssessment.count', -1 do
      delete :destroy, params: { id: @risk_assessment }
    end

    assert_redirected_to risk_assessments_url
  end

  test 'should get new item' do
    get :new_item, params: { id: @risk_assessment }, xhr: true, as: :js
    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'should get fetch item' do
    get :new_item, params: {
      id: @risk_assessment,
      risk_assessment_item_id: risk_assessment_items(:sox_section_13).id
    }, xhr: true, as: :js
    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'auto complete for business units' do
    get :auto_complete_for_business_unit, params: { q: 'fifth' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_units.size # Fifth is in another organization

    get :auto_complete_for_business_unit, params: { q: 'one' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_units.size # One only
    assert business_units.all? { |u| (u['label'] + u['informal']).match /one/i }

    get :auto_complete_for_business_unit, params: { q: 'business' }, as: :json
    assert_response :success

    business_units = ActiveSupport::JSON.decode(@response.body)

    assert_equal 4, business_units.size # All in the organization (one, two, three and four)
    assert business_units.all? { |u| (u['label'] + u['informal']).match /business/i }
  end
end
