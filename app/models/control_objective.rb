# frozen_string_literal: true

class ControlObjective < ApplicationRecord
  include ActiveStorage::HasOneFile
  include Auditable
  include ControlObjectives::AffectedSectorGal
  include ControlObjectives::AttributeTypes
  include ControlObjectives::AuditSectorsGal
  include ControlObjectives::Control
  include ControlObjectives::ControlObjectiveAuditors
  include ControlObjectives::Defaults
  include ControlObjectives::DestroyValidation
  include ControlObjectives::Json
  include ControlObjectives::Relevance
  include ControlObjectives::Risk
  include ControlObjectives::Search
  include ControlObjectives::Scopes
  include ControlObjectives::ScoreType
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

  # def support_aux=(attachable)
  #   byebug
  #   support_aux.attach(create_blob(attachable))
  #   byebug
  # end

  # def attachable_storage_path
  #   # [
  #   #   Apartment::Tenant.current.parameterize,
  #   #   'users',
  #   #   id,
  #   #   ActiveStorage::Blob.generate_unique_secure_token
  #   # ].compact.join('/')

  #   id_aux = ('%08d' % id).scan(/\d{4}/).join '/'

  #   File.join organization_id_path(organization_id), self.class.to_s.underscore.pluralize, id_aux
  # end

  # private

  #   def organization_id_path organization_id = Current.organization&.id
  #     ('%08d' % (organization_id || 0)).scan(/\d{4}/).join('/')
  #   end
end
