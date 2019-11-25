# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class LicenseTest < ActiveSupport::TestCase
  setup do
    @license = licenses :cirope
  end

  test 'create' do
    assert_difference 'License.count' do
      License.create! group: groups(:main_group), auditors_limit: 1
    end
  end

  test 'validates included attributes' do
    @license.auditors_limit = LICENSE_PLANS.keys.max.next

    assert @license.invalid?
    assert_error @license, :auditors_limit, :inclusion
  end

  test 'should be alive' do
    assert @license.alive?

    @license.status = :trial
    assert @license.alive?

    @license.status = :unpaid
    refute @license.alive?
  end

  test 'credit card is needed' do
    refute @license.payment_needed?

    @license.status = :trial
    @license.created_at = License::DEFAULT_TRIAL_PERIOD.ago

    assert @license.payment_needed?

    @license.reload
    @license.status = :unpaid

    assert @license.payment_needed?
  end

  test 'update status on payment' do
    @license.update_columns(
      status:          :trial,
      created_at:      32.days.ago,
      subscription_id: nil
    )

    assert @license.trial?

    @license.check_subscription

    assert @license.unpaid?
    assert_nil @license.paid_until

    @license.update_column :subscription_id, SecureRandom.uuid

    check_subscription_stubbed_status :paid

    assert @license.active?
    assert_equal 1.month.from_now.to_date, @license.paid_until.to_date

    check_subscription_stubbed_status :in_process

    assert @license.active?
    assert_equal 2.days.from_now.to_date, @license.paid_until.to_date

    # paid until 2 days from now
    check_subscription_stubbed_status :not_found

    assert @license.active?

    # Expired paid_until
    @license.update_column :paid_until, 2.seconds.ago

    check_subscription_stubbed_status :not_found

    assert @license.unpaid?
  end

  private

    def check_subscription_stubbed_status status
      response = case status
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

      PaypalClient.stub :get_subscription, response do
        @license.check_subscription
      end
    end
end
