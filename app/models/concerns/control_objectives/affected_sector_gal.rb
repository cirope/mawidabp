# frozen_string_literal: true

module ControlObjectives::AffectedSectorGal
  extend ActiveSupport::Concern

  included do
    belongs_to :affected_sector, class_name: 'Sector', optional: true
  end
end
