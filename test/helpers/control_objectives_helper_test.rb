# frozen_string_literal: true

require 'test_helper'

class ControlObjectivesHelperTest < ActionView::TestCase
  test 'Should return audit sectors gal' do
    expected = ControlObjective::GAL_AUDIT_SECTORS.map { |sector| [sector, sector] }

    assert_equal expected, gal_audit_sectors
  end
end
