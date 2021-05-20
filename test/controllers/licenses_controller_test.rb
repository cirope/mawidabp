# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class LicensesControllerTest < ActionController::TestCase
  setup do
    skip unless ENABLE_PUBLIC_REGISTRATION

    login
    set_organization
  end

  test 'get license' do
    get :show
    assert_response :success
  end

  test 'create subscription' do
    PaypalClient.stub :get_subscription, { status: :in_process } do
      patch :update, params: {
        license: { subscription_id: SecureRandom.uuid }
      }, xhr: true, as: :js
    end

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end
end
