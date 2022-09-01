# frozen_string_literal: true

module ControlObjectives::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, pdf_encoding: true, presence: true
    validates :relevance, :risk, numericality: { only_integer: true },
      allow_nil: true, allow_blank: true
    validate :has_control
    validate :uniqueness_control_objective_auditors
  end

  private

    def has_control
      has_active_control = control && !control.marked_for_destruction?

      errors.add :control, :blank unless has_active_control
    end

    def uniqueness_control_objective_auditors
      user_ids = []

      control_objective_auditors.each do |control_objective_auditor|
        if user_ids.include?(control_objective_auditor.user.id)
          control_objective_auditor.errors.add(:user_id, :taken)
          errors.add(:control_objective_auditors, :taken)
        else
          user_ids.push(control_objective_auditor.user.id)
        end
      end
    end
end
