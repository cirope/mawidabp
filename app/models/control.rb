class Control < ApplicationRecord
  include Auditable
  include Controls::Defaults
  include Controls::Validations
  include ParameterSelector

  attr_accessor :validates_presence_of_control,
                :validates_presence_of_effects,
                :validates_presence_of_design_tests,
                :validates_presence_of_compliance_tests,
                :validates_presence_of_sustantive_tests

  belongs_to :controllable, polymorphic: true, optional: true
end
