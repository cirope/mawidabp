# frozen_string_literal: true

module ControlObjectivesHelper
  def audit_sectors_gal
    ControlObjective::AUDIT_SECTORS_GAL.map do |sector|
      [sector, sector]
    end
  end
end
