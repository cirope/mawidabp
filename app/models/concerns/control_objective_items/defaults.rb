module ControlObjectiveItems::Defaults
  extend ActiveSupport::Concern

  included do
    before_validation :set_control_objective_text, on: :create
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.relevance       ||= control_objective.relevance if control_objective
      self.finished        ||= false
      self.organization_id ||= Organization.current_id

      build_control unless control
    end

    def set_control_objective_text
      self.control_objective_text ||= control_objective&.name
    end
end
