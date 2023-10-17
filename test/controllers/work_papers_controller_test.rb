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

  test 'upadte work papers' do
    login user: users(:auditor)

    @work_paper = work_papers :image_work_paper

    assert @work_paper.pending?

    patch :update, params: { id: @work_paper }, xhr: true, as: :js

    assert @work_paper.reload.finished?
  end
end
