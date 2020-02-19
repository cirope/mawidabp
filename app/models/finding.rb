class Finding < ApplicationRecord
  include ActsAsTree
  include Auditable
  include Comparable
  include Findings::Achievements
  include Findings::Answers
  include Findings::AttributeTypes
  include Findings::Brief
  include Findings::BusinessUnits
  include Findings::ByUserCsv
  include Findings::Code
  include Findings::Comments
  include Findings::Confirmation
  include Findings::ControlObjective
  include Findings::Cost
  include Findings::CreateValidation
  include Findings::Csv
  include Findings::Current
  include Findings::CurrentSituationCsv
  include Findings::CustomAttributes
  include Findings::Defaults
  include Findings::DestroyValidation
  include Findings::Display
  include Findings::Expiration
  include Findings::FinalReview
  include Findings::FirstFollowUp
  include Findings::FollowUp
  include Findings::FollowUpPdf
  include Findings::ImportantDates
  include Findings::Json
  include Findings::NotificationLevel
  include Findings::Notifications
  include Findings::Overrides
  include Findings::Pdf
  include (POSTGRESQL_ADAPTER ? Findings::Reiterations : Findings::ReiterationsAlt)
  include Findings::Relations
  include Findings::ReportScopes
  include Findings::Reschedule
  include Findings::SaveCallbacks
  include Findings::ScaffoldFollowUp
  include Findings::ScaffoldNotifications
  include Findings::Scopes
  include Findings::Search
  include Findings::SerializedAttributes
  include Findings::SortColumns
  include Findings::State
  include Findings::StateDates
  include Findings::Taggable
  include Findings::Tasks
  include Findings::Unanswered
  include Findings::UnansweredNotifications
  include Findings::Unconfirmed
  include Findings::UpdateCallbacks
  include Findings::UserAssignments
  include Findings::UserScopes
  include Findings::ValidationCallbacks
  include Findings::Validations
  include Findings::Versions
  include Findings::WeaknessReportPdf
  include Findings::WorkPapers
  include ParameterSelector
  include Parameters::Priority
  include Parameters::Risk

  acts_as_tree

  belongs_to :organization
  has_many :finding_review_assignments, dependent: :destroy, inverse_of: :finding
end
