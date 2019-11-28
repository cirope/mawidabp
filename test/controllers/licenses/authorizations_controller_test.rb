# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class Licenses::AuthorizationsControllerTest < ActionController::TestCase
  setup do
    skip unless ENABLE_PUBLIC_REGISTRATION

    login
    set_organization
  end

  test 'get auditors limit form' do
    get :new
    assert_response :success
  end

  test 'try to downgrade license' do
    post :create, params: {
      license: {
        auditors_limit: 5
      }
    }

    assert_response :success
    assert_template 'licenses/authorizations/_form'
  end

  test 'change auditors limit' do
    Current.group.license.update_column :auditors_limit, 1

    result = {
      status:   :success,
      response: 'http://auth.sample'
    }

    PaypalClient.stub :authorize_change_of_plan, result do
      post :create, params: {
        license: {
          auditors_limit: 10
        }
      }
    end

    assert_redirected_to license_url
  end
end
