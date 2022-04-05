# frozen_string_literal: true

class ControlObjectiveAuditor < ApplicationRecord
  include ControlObjectiveAuditors::Validations

  belongs_to :user
  belongs_to :control_objective
end
