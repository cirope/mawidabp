# frozen_string_literal: true

require 'test_helper'

class PaypalControllerTest < ActionController::TestCase
  test 'create paypal webhook' do
    assert_difference 'Webhook.count' do
      post :create, params: {
        resource_type: 'subscription',
        event_type:    'BILLING.SUBSCRIPTION.ACTIVATED',
        resource:      { id: '123' }
      }, as: :json
    end
  end
end
