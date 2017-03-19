class Control < ApplicationRecord
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  attr_accessor :validates_presence_of_control, :validates_presence_of_effects,
    :validates_presence_of_design_tests, :validates_presence_of_compliance_tests,
    :validates_presence_of_sustantive_tests

  # Restricciones
  validates :control, presence: true, if: :validates_presence_of_control
  validates :effects, presence: true, if: :validates_presence_of_effects
  validates :design_tests, presence: true, if: :validates_presence_of_design_tests
  validates :compliance_tests, presence: true, if: :validates_presence_of_compliance_tests
  validates :sustantive_tests, presence: true, if: :validates_presence_of_sustantive_tests
  validates :control, :effects, :design_tests, :compliance_tests,
    :sustantive_tests, pdf_encoding: true

  # Relaciones
  belongs_to :controllable, polymorphic: true

  def initialize(attributes = nil)
    super(attributes)

    self.order ||= 1
  end
end
