# frozen_string_literal: true

require 'redis_client'

module Licenses::Gateway
  extend ActiveSupport::Concern

  included do
    after_update :clean_vendor_auth_url, if: :saved_change_to_auditors_limit?
  end

  def alive?
    trial? || active?
  end

  def blocked?
    unpaid? || cancelled?
  end

  def payment_needed?
    unpaid? || trial_ending?
  end

  def trial_valid_until
    created_at + License::DEFAULT_TRIAL_PERIOD
  end

  def trial_ending?
    trial? && (trial_valid_until - License::NOTICE_PERIOD) <= Time.zone.now
  end

  def price_per_month
    LICENSE_PLANS[auditors_limit]['price'].to_f
  end

  def plan_id
    LICENSE_PLANS[auditors_limit]['plan_id']
  end

  def change_auditors_limit auditors_limit
    case
    when LICENSE_PLANS[auditors_limit].nil?
      errors.add :auditors_limit, :invalid
    when (count = group.auditor_users_count) > auditors_limit
      errors.add :auditors_limit, :greater_than_or_equal_to, count: count
    when subscription_id.blank?
      update auditors_limit: auditors_limit
    when self.auditors_limit > auditors_limit
      errors.add :auditors_limit, :cannot_downgrade
    when self.auditors_limit < auditors_limit
      authorize_change_of_plan auditors_limit
    end
  end

  def authorize_change_of_plan auditors_limit
    result = PaypalClient.authorize_change_of_plan subscription_id, LICENSE_PLANS[auditors_limit][:plan_id]

    if result[:status] == :success
      self.plan_change_url = result[:response]
    else
      errors.add :base, result[:response]
    end
  end

  def plan_change_url
    @plan_change_url ||= RedisMwClient.license_plan_change_url subscription_id
  end

  def plan_change_url= url
    RedisMwClient.assign_license_plan_change_url subscription_id, url
  end

  def check_subscription
    return if cancelled?

    if subscription_id.blank?
      unpaid! if trial_valid_until <= Time.zone.now
    else
      process_subscription PaypalClient.get_subscription(subscription_id)
    end
  end

  def process_subscription result
    if result[:status] == :paid && result[:paid_until] > Time.zone.now
      update status: :active, paid_until: result[:paid_until],
        auditors_limit: auditors_limit_from_plan_id(result[:plan_id])
    elsif result[:status] == :in_process
      update status: :active, paid_until: 2.days.from_now
    elsif !unpaid? && (paid_until.blank? || paid_until < Time.zone.now)
      update status: :unpaid
    end
  end

  def auditors_limit_from_plan_id plan_id
    LICENSE_PLANS.find { |_k, v| v[:plan_id] == plan_id }.first
  end

  def clean_vendor_auth_url
    RedisMwClient.clean_license_plan_change_url subscription_id
  end
end
