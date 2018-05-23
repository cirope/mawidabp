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
      'FileModel.count',
      'RiskAssessment.count',
      'RiskAssessmentItem.count',
      'RiskWeight.count'
    ]

    assert_difference counts do
      post :create, params: {
        risk_assessment: {
          name: 'New risk assessment',
          description: 'New risk assessment description',
          period_id: periods(:unused_period).id,
          risk_assessment_template_id: risk_assessment_templates(:sox).id,
          file_model_attributes: {
            file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
          },
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

  test 'should show risk assessment as PDF' do
    get :show, params: { id: @risk_assessment }, as: :pdf
    assert_redirected_to @risk_assessment.relative_pdf_path
  end

  test 'should show risk assessment as CSV' do
    get :show, params: { id: @risk_assessment }, as: :csv

    assert_response :success
    assert_equal Mime[:csv], @response.content_type
  end

  test 'should get edit' do
    get :edit, params: { id: @risk_assessment }
    assert_response :success
  end

  test 'should update risk assessment and redirect to edit' do
    patch :update, params: {
      id: @risk_assessment, risk_assessment: { name: 'Updated name' }
    }

    assert_redirected_to edit_risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should update risk assessment and redirect to show' do
    patch :update, params: {
      id: @risk_assessment, risk_assessment: { status: 'final' }
    }

    assert_redirected_to risk_assessment_url(assigns(:risk_assessment))
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

  test 'should get add items for best practices' do
    get :add_items, params: {
      id: @risk_assessment,
      ids: [best_practices(:iso_27001).id],
      type: 'best_practice'
    }, xhr: true, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end

  test 'should get add items for business unit types' do
    get :add_items, params: {
      id: @risk_assessment,
      ids: [business_unit_types(:cycle).id],
      type: 'business_unit_type'
    }, xhr: true, as: :js

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

  test 'should sort by risk' do
    patch :sort_by_risk, params: { id: @risk_assessment }

    assert_redirected_to edit_risk_assessment_url(assigns(:risk_assessment))
  end

  test 'should create plan' do
    period = periods :unused_period

    @risk_assessment.update_column :period_id, period.id

    assert_difference 'Plan.count' do
      post :merge_to_plan, params: { id: @risk_assessment }
    end

    assert_redirected_to edit_plan_url(Plan.find_by period_id: period.id)
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

  test 'auto complete for business unit type' do
    get :auto_complete_for_business_unit_type, params: { q: 'noway' }, as: :json
    assert_response :success

    business_unit_types = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, business_unit_types.size # Fifth is in another organization

    get :auto_complete_for_business_unit_type, params: { q: 'cycle' }, as: :json
    assert_response :success

    business_unit_types = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, business_unit_types.size # One only
    assert business_unit_types.all? { |u| u['label'].match /cycle/i }
  end

  test 'auto complete for best practices' do
    get :auto_complete_for_best_practice, xhr: true, params: {
      q: 'a'
    }, as: :json
    assert_response :success

    best_practices = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, best_practices.size
    assert best_practices.all? { |bp| bp['label'].match /a/i }

    get :auto_complete_for_best_practice, xhr: true, params: {
      q: 'iso'
    }, as: :json
    assert_response :success

    best_practices = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, best_practices.size
    assert best_practices.all? { |bp| bp['label'].match /iso/i }

    get :auto_complete_for_best_practice, xhr: true, params: {
      q: 'xyz'
    }, as: :json
    assert_response :success

    best_practices = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, best_practices.size # None
  end
end
