# frozen_string_literal: true

class Webhook < ApplicationRecord
  enum status: {
    pending:   'pending',
    processed: 'processed',
    error:     'error'
  }

  def process
    processed = case gateway
                when 'paypal'
                  License.find_by(subscription_id: reference_id)&.check_subscription
                end

    processed ? processed! : error!
  end
end
