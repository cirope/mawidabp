class ConclusionReview < ApplicationRecord
  include Auditable
  include ParameterSelector
  include ConclusionReviews::Annexes
  include ConclusionReviews::AttributeTypes
  include ConclusionReviews::BicPdf
  include ConclusionReviews::BundleIndexPdf
  include ConclusionReviews::BundleZip
  include ConclusionReviews::ConclusionIndex
  include ConclusionReviews::CoverPdf
  include ConclusionReviews::CroPdf
  include ConclusionReviews::DefaultPdf
  include ConclusionReviews::DestroyValidation
  include ConclusionReviews::Email
  include ConclusionReviews::FindingsFollowUpPdf
  include ConclusionReviews::FindingsSheetPdf
  include ConclusionReviews::GalPdf
  include ConclusionReviews::NbcPdf
  include ConclusionReviews::PatPdf
  include ConclusionReviews::PatRtf
  include ConclusionReviews::Pdf
  include ConclusionReviews::Review
  include ConclusionReviews::Rtf
  include ConclusionReviews::Scopes
  include ConclusionReviews::Search
  include ConclusionReviews::SortColumns
  include ConclusionReviews::UplPdf
  include ConclusionReviews::Validations
  include ConclusionReviews::WorkflowPdf

  attr_readonly :review_id

  belongs_to :organization
  has_one :plan_item, through: :review
  has_many :control_objective_items, through: :review
  has_many :polls, as: :pollable

  def has_final_review?
    review&.has_final_review?
  end
end
