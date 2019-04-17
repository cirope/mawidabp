class ControlObjective < ApplicationRecord
  include Auditable
  include ControlObjectives::AttributeTypes
  include ControlObjectives::Control
  include ControlObjectives::Defaults
  include ControlObjectives::DestroyValidation
  include ControlObjectives::JSON
  include ControlObjectives::Risk
  include ControlObjectives::Search
  include ControlObjectives::Scopes
  include ControlObjectives::Shared
  include ControlObjectives::Validations
  include Parameters::Relevance
  include Parameters::Risk
  include Taggable

  mount_uploader :support, FileUploader

  delegate :organization_id, to: :best_practice, allow_nil: true

  belongs_to :process_control, optional: true
  has_one :best_practice, through: :process_control
  has_many :control_objective_items, inverse_of: :control_objective,
    dependent: :nullify
  has_many :control_objective_weakness_template_relations, dependent: :destroy
  has_many :weakness_templates, through: :control_objective_weakness_template_relations

  def to_s
    name
  end

  def label
    name
  end

  def informal
    process_control&.name
  end

  def identifier
    support.identifier || support_identifier
  end
end
