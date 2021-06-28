module ControlObjectives::Control
  extend ActiveSupport::Concern

  included do
    before_validation :enable_control_validations, if: :enable_control_validations?

    has_one :control, -> {
      order Arel.sql("#{Control.quoted_table_name}.#{Control.qcn('order')} ASC")
    }, as: :controllable, dependent: :destroy

    accepts_nested_attributes_for :control, allow_destroy: true
  end

  private

    def enable_control_validations
      control&.validates_presence_of_effects          = true
      control&.validates_presence_of_compliance_tests = true
    end

    def enable_control_validations?
      !HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS &&
        HIDE_FINDING_CRITERIA_MISMATCH
    end
end
