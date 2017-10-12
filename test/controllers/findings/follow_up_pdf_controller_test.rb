require 'test_helper'

class Findings::FollowUpPdfControllerTest < ActionController::TestCase
  setup do
    @finding = findings :unconfirmed_weakness

    login
  end

  test 'should get show' do
    get :show, params: { completed: 'incomplete', id: @finding }

    assert_redirected_to @finding.relative_follow_up_pdf_path
  end
end
