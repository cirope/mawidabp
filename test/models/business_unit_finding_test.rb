require 'test_helper'

class BusinessUnitFindingTest < ActiveSupport::TestCase
  def setup
    @business_unit_finding = business_unit_findings :business_unit_three_finding
  end

  test 'blank attributes' do
    @business_unit_finding.business_unit_id = nil

    assert @business_unit_finding.invalid?
    assert_error @business_unit_finding, :business_unit_id, :blank
  end
end
