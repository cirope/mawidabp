# frozen_string_literal: true

module ControlObjectiveAuditors::Validations
  extend ActiveSupport::Concern

  included do
    validate :user_is_auditor_or_audited
  end

  private

    def user_is_auditor_or_audited
      errors.add(:user_id, :invalid) unless (user.auditor? || user.audited?)
    end
end
