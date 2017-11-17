module Controls::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      default_design_test = ENV['DEFAULT_CONTROL_DESIGN_TEST_VALUE']

      self.order ||= 1
      self.design_tests ||= default_design_test if default_design_test.present?
    end
end
