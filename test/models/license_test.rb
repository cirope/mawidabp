require 'test_helper'

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
    refute @license.credit_card_needed?

    @license.status = :trial
    @license.created_at = License::DEFAULT_TRIAL_PERIOD.ago

    assert @license.credit_card_needed?

    @license.reload
    @license.status = :unpaid

    assert @license.credit_card_needed?

    @license.reload
    @license.subscribed_until = 2.days.from_now

    assert @license.credit_card_needed?
  end
end
