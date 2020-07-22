require 'test_helper'

class BusinessUnitTypeUserTest < ActiveSupport::TestCase
  setup do
    @business_unit_type_user = business_unit_type_users :poll_cycle_relation
  end

  test 'blank attributes' do
    @business_unit_type_user.user_id = ''
    @business_unit_type_user.business_unit_type_id = ''

    assert @business_unit_type_user.invalid?
    assert_error @business_unit_type_user, :user, :blank
    assert_error @business_unit_type_user, :business_unit_type, :blank
  end

  test 'unique attributes' do
    business_unit_type_user = @business_unit_type_user.dup

    assert business_unit_type_user.invalid?
    assert_error business_unit_type_user, :business_unit_type_id, :taken
  end
end
