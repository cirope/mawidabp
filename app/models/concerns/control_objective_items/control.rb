module ControlObjectiveItems::Control
  extend ActiveSupport::Concern

  included do
    before_validation :enable_control_validations

    has_one :control, as: :controllable, dependent: :destroy

    accepts_nested_attributes_for :control, allow_destroy: true
  end

  private

    def enable_control_validations
      if finished && !exclude_from_score
        control.validates_presence_of_control = true
        control.validates_presence_of_effects = true

        control.validates_presence_of_compliance_tests = compliance_score.present?
        control.validates_presence_of_design_tests     = design_score.present?
        control.validates_presence_of_sustantive_tests = sustantive_score.present?
      end
    end
end
