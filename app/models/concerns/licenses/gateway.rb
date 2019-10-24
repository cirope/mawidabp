module Licenses::Gateway
  extend ActiveSupport::Concern

  def alive?
    trial? || active?
  end

  def credit_card_needed?
    unpaid? || trial_ending? || subscription_ending?
  end

  def trial_ending?
    trial? && (created_at + License::DEFAULT_TRIAL_PERIOD - License::NOTICE_PERIOD) <= Time.zone.now
  end

  def subscription_ending?
    active? && subscribed_until && (subscribed_until - License::NOTICE_PERIOD) <= Time.zone.now
  end
end
