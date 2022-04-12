class Review < ApplicationRecord
  include Auditable
  include Parameters::Risk
  include Parameters::Score
  include ParameterSelector
  include Reviews::AutomaticIdentification
  include Reviews::Approval
  include Reviews::BestPracticeComments
  include Reviews::Clone
  include Reviews::ConclusionReview
  include Reviews::ControlObjectiveItems
  include Reviews::Counts
  include Reviews::DestroyValidation
  include Reviews::ExternalReviews
  include Reviews::FileModelReviews
  include Reviews::FindingAssignments
  include Reviews::FindingCode
  include Reviews::Findings
  include Reviews::FinishedWorkPapers
  include Reviews::Interviews
  include Reviews::IssueDate
  include Reviews::Overrides
  include Reviews::PlanItem
  include Reviews::Previous
  include Reviews::Pdf
  include Reviews::Reorder
  include Reviews::Scopes
  include Reviews::Score
  include Reviews::ScoreDetails
  include Reviews::ScoreSheet
  include Reviews::ScoreSheetCommon
  include Reviews::ScoreSheetGlobal
  include Reviews::Search
  include Reviews::SortColumns
  include Reviews::SurveyPdf
  include Reviews::TypeReview
  include Reviews::UpdateCallbacks
  include Reviews::Users
  include Reviews::Validations
  include Reviews::WeaknessesBrief
  include Reviews::WorkPapers
  include Reviews::WorkPapersZip
  include Taggable
  include Trimmer

  trimmed_fields :identification

  belongs_to :period
  belongs_to :organization
  has_one :workflow, dependent: :destroy
  has_many :business_unit_scores, through: :control_objective_items
  has_many :time_consumptions, as: :resource, dependent: :destroy

  def long_identification
    "#{identification} - #{plan_item.project}"
  end
end
