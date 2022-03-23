# frozen_string_literal: true

module ControlObjectives::AuditSectorsGal
  extend ActiveSupport::Concern

  included do
    GAL_AUDIT_SECTORS = %w[AP AF AC AS]
  end
end
