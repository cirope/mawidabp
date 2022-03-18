# frozen_string_literal: true

module ControlObjectives::AuditSectorsGal
  extend ActiveSupport::Concern

  included do
    AUDIT_SECTORS_GAL = %w[AP AF AC AS]
  end
end
