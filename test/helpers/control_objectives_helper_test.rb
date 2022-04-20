# frozen_string_literal: true

require 'test_helper'

class ControlObjectivesHelperTest < ActionView::TestCase
  test 'Should return audit sectors gal' do
    expected = ControlObjective::GAL_AUDIT_SECTORS.map { |sector| [sector, sector] }

    assert_equal expected, gal_audit_sectors
  end

  test 'Should return affected sectors' do
    Current.organization = organizations :cirope
    expected             = Sector.list.map { |s| [s.name, s.id] }

    assert_equal expected, affected_sectors
  end
end
