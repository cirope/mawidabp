# frozen_string_literal: true

module ControlObjectives::ControlObjectiveAuditors
  extend ActiveSupport::Concern

  included do
    has_many :control_objective_auditors, dependent: :destroy
    has_many :auditors, through: :control_objective_auditors, source: :user

    accepts_nested_attributes_for :control_objective_auditors, allow_destroy: true, reject_if: :all_blank
  end
end
