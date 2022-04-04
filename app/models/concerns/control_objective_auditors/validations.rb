# frozen_string_literal: true

module ControlObjectiveAuditors::Validations
  extend ActiveSupport::Concern

  included do
    validate :user_is_auditor
  end

  private

    def user_is_auditor
      errors.add(:user_id, :invalid) unless user.auditor?
    end
end
