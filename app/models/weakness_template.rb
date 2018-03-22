class WeaknessTemplate < ApplicationRecord
  include Auditable
  include Parameters::Risk
  include WeaknessTemplates::ControlObjectives
  include WeaknessTemplates::JSON
  include WeaknessTemplates::Risk
  include WeaknessTemplates::Scopes
  include WeaknessTemplates::Search
  include WeaknessTemplates::SerializedAttributes
  include WeaknessTemplates::Validations

  belongs_to :organization
  has_many :weaknesses, dependent: :nullify
end
