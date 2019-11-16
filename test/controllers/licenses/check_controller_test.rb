# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class Licenses::CheckControllerTest < ActionController::TestCase
  setup do
    skip unless ENABLE_PUBLIC_REGISTRATION

    login
    set_organization
  end

  test 'check license' do
    Current.group.license.update_column :status, :unpaid

    check_subscription_stubbed_status :unpaid

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type

    check_subscription_stubbed_status :paid

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end

  private

    def check_subscription_stubbed_status status
      stubbed_response = case status
                         when :paid
                           {
                             status:     status,
                             paid_until: 1.month.from_now
                           }
                         when :in_process
                           { status: status }
                         else
                           { status: :not_found }
                         end

      PaypalClient.stub :get_subscription, stubbed_response do
        post :create, xhr: true, as: :js
      end
    end
end
