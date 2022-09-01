# frozen_string_literal: true

namespace :licenses do
  desc 'Process Webhooks'
  task process_webhooks: :environment do
    Webhook.pending.find_each do |webhook|
      webhook.process
    rescue => e
      Rails.logger.error e
      webhook.error!
    end
  end

  desc 'Check Licenses subscriptions'
  task check_subscriptions: :environment do
    License.past_due.or(License.unpaid).find_each do |license|
      license.check_subscription
    rescue => e
      Rails.logger.error e
    end
  end
end
