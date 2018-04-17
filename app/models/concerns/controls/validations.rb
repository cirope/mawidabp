module Controls::Validations
  extend ActiveSupport::Concern

  included do
    validates :control,          presence: true, if: :validates_presence_of_control
    validates :effects,          presence: true, if: :validates_presence_of_effects
    validates :design_tests,     presence: true, if: :validates_presence_of_design_tests
    validates :compliance_tests, presence: true, if: :validates_presence_of_compliance_tests
    validates :sustantive_tests, presence: true, if: :validates_presence_of_sustantive_tests
    validates :control,
              :effects,
              :design_tests,
              :compliance_tests,
              :sustantive_tests, pdf_encoding: true
  end
end
