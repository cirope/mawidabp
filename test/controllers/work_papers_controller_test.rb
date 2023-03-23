# frozen_string_literal: true

require 'test_helper'

class WorkPapersControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'show work papers' do
    get :show, params: { file_url: 'https://docs.google.com/' }, xhr: true, as: :js
    assert_response :success
    assert_template 'work_papers/show'
    assert @response.body.match /iframe/
  end
end
