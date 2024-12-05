# frozen_string_literal: true

require 'test_helper'

class OptionsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'edit options' do
    skip unless REVIEW_MANUAL_SCORE

    get :edit
    assert_response :success
    assert_not_nil assigns(:current_scores)
    assert_template 'options/edit'
  end

  test 'should update options' do
    skip unless REVIEW_MANUAL_SCORE

    Current.organization = organizations :cirope

    options = {
      '1' => [ 'satisfactory',   45 ],
      '2' => [ 'unsatisfactory', 10 ]
    }

    assert_equal Organization::DEFAULT_SCORES.count, Current.organization.current_scores.count

    patch :update, params: { options: options }

    assert_redirected_to edit_options_path
    assert_equal options.count, Current.organization.current_scores.count
  end
end
