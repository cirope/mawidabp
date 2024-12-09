# frozen_string_literal: true

module ControlObjectivesHelper
  def gal_audit_sectors
    ControlObjective::GAL_AUDIT_SECTORS.map do |sector|
      [sector, sector]
    end
  end

  def affected_sectors
    Sector.list.map { |s| [s.name, s.id] }
  end
end
