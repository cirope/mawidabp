# frozen_string_literal: true

require 'test_helper'

class SectorTest < ActiveSupport::TestCase
  test 'blank attributes' do
    sector                 = sectors :first_sector
    sector.name            = ''
    sector.organization_id = ''

    assert sector.invalid?
    assert_error sector, :name, :blank
    assert_error sector, :organization, :blank
  end

  test 'scope list for organization' do
    cirope_organization = organizations :cirope
    Current.organization = cirope_organization
    expected = Sector.where(organization_id: cirope_organization.id).order name: :asc

    assert_equal expected, Sector.list
  end
end
