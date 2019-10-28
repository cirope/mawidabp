# frozen_string_literal: true

class PaypalController < ApplicationController
  def create
    Webhook.create!(
      gateway:      'paypal',
      status:       'pending',
      kind:         params['event_type'],
      reference_id: params['resource']['id']
    ) if params['resource_type'] == 'subscription'

    render body: nil, status: 200
  end
end
