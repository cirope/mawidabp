class PlanItem < ApplicationRecord
  include Auditable
  include Comparable
  include ParameterSelector
  include PlanItems::Comparable
  include PlanItems::DateColumns
  include PlanItems::DestroyValidation
  include PlanItems::PDF
  include PlanItems::ResourceUtilizations
  include PlanItems::Scopes
  include PlanItems::Spread
  include PlanItems::Stats
  include PlanItems::Status
  include PlanItems::Units
  include PlanItems::Validations
  include Taggable

  attr_accessor :overloaded

  belongs_to :plan, optional: true
  belongs_to :business_unit, optional: true
  has_one :review
  has_one :conclusion_final_review, through: :review
  has_one :business_unit_type, through: :business_unit
end
