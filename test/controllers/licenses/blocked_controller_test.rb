# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class Licenses::BlockedControllerTest < ActionController::TestCase
  setup do
    skip unless ENABLE_PUBLIC_REGISTRATION

    login
    set_organization
  end

  test 'show blocked license' do
    get :show
    assert_response :success
  end
end
