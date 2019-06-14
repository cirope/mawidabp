require 'test_helper'

class PermalinksControllerTest < ActionController::TestCase
  setup do
    @permalink = permalinks :link

    login
  end

  test 'show user' do
    get :show, params: { id: @permalink }

    assert_redirected_to @permalink.as_options
  end
end
