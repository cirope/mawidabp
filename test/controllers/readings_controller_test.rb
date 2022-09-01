require 'test_helper'

class ReadingsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'should get create' do
    assert_difference 'Reading.count' do
      post :create, xhr: true, as: :js, params: {
        id:   finding_answers(:auditor_answer).id,
        type: 'FindingAnswer'
      }
    end

    assert_response :success
  end
end
