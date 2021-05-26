require 'test_helper'

class BusinessUnitKindTest < ActiveSupport::TestCase
  setup do
    @business_unit_kind = business_unit_kinds :branch
  end

  test 'blank attributes' do
    @business_unit_kind.name = ''
    @business_unit_kind.organization_id = nil

    assert @business_unit_kind.invalid?
    assert_error @business_unit_kind, :name, :blank
    assert_error @business_unit_kind, :organization, :blank
  end

  test 'unique attributes' do
    business_unit_kind = @business_unit_kind.dup

    assert business_unit_kind.invalid?
    assert_error business_unit_kind, :name, :taken
  end
end
