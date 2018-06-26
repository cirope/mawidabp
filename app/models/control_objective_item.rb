class ControlObjectiveItem < ApplicationRecord
  include Auditable
  include Comparable
  include Parameters::Relevance
  include Parameters::Qualification
  include ParameterSelector
  include ControlObjectiveItems::Approval
  include ControlObjectiveItems::AttributeTypes
  include ControlObjectiveItems::BusinessUnitScores
  include ControlObjectiveItems::Control
  include ControlObjectiveItems::ControlObjective
  include ControlObjectiveItems::Defaults
  include ControlObjectiveItems::DestroyValidation
  include ControlObjectiveItems::Effectiveness
  include ControlObjectiveItems::FindingPDFData
  include ControlObjectiveItems::Findings
  include ControlObjectiveItems::Overrides
  include ControlObjectiveItems::PDF
  include ControlObjectiveItems::Relevance
  include ControlObjectiveItems::Scopes
  include ControlObjectiveItems::Scores
  include ControlObjectiveItems::Search
  include ControlObjectiveItems::UpdateCallbacks
  include ControlObjectiveItems::Validations
  include ControlObjectiveItems::WorkPapers

  alias_attribute :label, :control_objective_text

  belongs_to :organization
  belongs_to :review, inverse_of: :control_objective_items

  def informal
    review&.to_s
  end

  def is_in_a_final_review?
    review&.has_final_review?
  end
end
