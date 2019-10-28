# frozen_string_literal: true

module Licenses::Gateway
  extend ActiveSupport::Concern

  def alive?
    trial? || active?
  end

  def payment_needed?
    unpaid? || trial_ending?
  end

  def trial_ending?
    trial? && (created_at + License::DEFAULT_TRIAL_PERIOD - License::NOTICE_PERIOD) <= Time.zone.now
  end

  def price_per_month
    LICENSE_PLANS[auditors_limit]['price'].to_f
  end

  def check_subscription
    return if cancelled? || subscription_id.blank?

    process_subscription PaypalClient.get_subscription(subscription_id)
  end

  def process_subscription result
    if result[:status] == :paid && result[:paid_until] > Time.zone.now
      update status: :active, paid_until: result[:paid_until]
    elsif result[:status] == :in_process
      update status: :active, paid_until: 2.days.from_now
    elsif !unpaid? && (paid_until.blank? || paid_until < Time.zone.now)
      update status: :unpaid
    end
  end
end
