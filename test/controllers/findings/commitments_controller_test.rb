require 'test_helper'

class Findings::CommitmentsControllerTest < ActionController::TestCase
  setup do
    @finding = findings :unconfirmed_weakness

    login
  end

  test 'should show commitment' do
    get :show, params: {
      completion_state: 'incomplete',
      finding_id: @finding,
      id: 10.months.from_now.to_date.to_s(:db),
      index: '2'
    }, xhr: true, as: :js

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end
end
