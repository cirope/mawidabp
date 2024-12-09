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
    assert_template 'options/edit'
  end

  test 'should update options' do
    skip unless REVIEW_MANUAL_SCORE

    type                 = 'manual_scores'
    Current.organization = organizations :cirope
    options              = {
                            '1' => [ 'satisfactory',   45 ],
                            '2' => [ 'unsatisfactory', 10 ]
                          }

    assert_equal 0, Current.organization.current_scores_by(type).count

    patch :update, params: { options: options }

    assert_redirected_to edit_options_path(type: type)
    assert_equal options.count,
      Current.organization.current_scores_by(type).count
  end
end
