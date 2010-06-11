class Control < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  attr_accessor :validates_presence_of_control, :validates_presence_of_effects,
    :validates_presence_of_design_tests, :validates_presence_of_compliance_tests

  # Restricciones
  validates_presence_of :control, :if => :validates_presence_of_control
  validates_presence_of :effects, :if => :validates_presence_of_effects
  validates_presence_of :design_tests,
    :if => :validates_presence_of_design_tests
  validates_presence_of :compliance_tests,
    :if => :validates_presence_of_compliance_tests

  # Relaciones
  belongs_to :controllable, :polymorphic => true

  def initialize(attributes = nil)
    super(attributes)

    self.order ||= 1
  end
end