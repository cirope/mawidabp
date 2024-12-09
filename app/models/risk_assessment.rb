class RiskAssessment < ApplicationRecord
  include Auditable
  include RiskAssessments::AttributeTypes
  include RiskAssessments::Clone
  include RiskAssessments::Csv
  include RiskAssessments::DestroyValidation
  include RiskAssessments::FileModel
  include RiskAssessments::Formula
  include RiskAssessments::Heatmap
  include RiskAssessments::Pdf
  include RiskAssessments::Plan
  include RiskAssessments::RiskAssessmentItems
  include RiskAssessments::RiskAssessemntWeights
  include RiskAssessments::Scopes
  include RiskAssessments::Search
  include RiskAssessments::Sort
  include RiskAssessments::Status
  include RiskAssessments::UpdateCallbacks
  include RiskAssessments::Validations
  include Shareable

  attr_accessor :cloned_from

  belongs_to :period, optional: true
  belongs_to :plan, optional: true
  belongs_to :risk_assessment_template, optional: true
  belongs_to :organization
  belongs_to :group
end
