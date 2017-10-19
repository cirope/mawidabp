class ConclusionReview < ApplicationRecord
  include Auditable
  include ParameterSelector
  include ConclusionReviews::BundleIndexPDF
  include ConclusionReviews::BundleZip
  include ConclusionReviews::CoverPDF
  include ConclusionReviews::DateColumns
  include ConclusionReviews::DestroyValidation
  include ConclusionReviews::Email
  include ConclusionReviews::FindingsFollowUpPDF
  include ConclusionReviews::FindingsSheetPDF
  include ConclusionReviews::PDF
  include ConclusionReviews::Scopes
  include ConclusionReviews::Search
  include ConclusionReviews::SortColumns
  include ConclusionReviews::Validations
  include ConclusionReviews::WorkflowPdf

  attr_readonly :review_id

  belongs_to :review
  belongs_to :organization
  has_one :plan_item, through: :review
  has_many :control_objective_items, through: :review
  has_many :polls, as: :pollable

  def has_final_review?
    review&.has_final_review?
  end
end
