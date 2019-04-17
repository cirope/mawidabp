require 'test_helper'

class Plans::ResourcesControllerTest < ActionController::TestCase
  setup do
    @plan = plans :current_plan

    login
  end

  test 'should get show' do
    get :show, params: { id: @plan }
    assert_response :success
  end

  test 'should get show as PDF' do
    get :show, params: { id: @plan }, as: :pdf
    assert_response :redirect
  end
end
