# frozen_string_literal: true

require 'test_helper'

class ControlObjectivesHelperTest < ActionView::TestCase
  test 'Should return audit sectors gal' do
    expected = ControlObjective::AUDIT_SECTORS_GAL.map { |sector| [sector, sector] }

    assert_equal expected, audit_sectors_gal
  end
end
