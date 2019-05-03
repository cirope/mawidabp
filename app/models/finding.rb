class Finding < ApplicationRecord
  include ActsAsTree
  include Auditable
  include Comparable
  include Findings::Achievements
  include Findings::AttributeTypes
  include Findings::Answers
  include Findings::BusinessUnits
  include Findings::Brief
  include Findings::Code
  include Findings::Comments
  include Findings::Confirmation
  include Findings::ControlObjective
  include Findings::Cost
  include Findings::CreateValidation
  include Findings::CSV
  include Findings::CustomAttributes
  include Findings::Defaults
  include Findings::DestroyValidation
  include Findings::Display
  include Findings::Expiration
  include Findings::FinalReview
  include Findings::FirstFollowUp
  include Findings::FollowUp
  include Findings::FollowUpPDF
  include Findings::ImportantDates
  include Findings::JSON
  include Findings::Notifications
  include Findings::NotificationLevel
  include Findings::Overrides
  include Findings::PDF
  include Findings::Reiterations
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
  include Findings::Tasks
  include Findings::Unanswered
  include Findings::Unconfirmed
  include Findings::UpdateCallbacks
  include Findings::UserAssignments
  include Findings::UserScopes
  include Findings::Validations
  include Findings::ValidationCallbacks
  include Findings::Versions
  include Findings::WorkPapers
  include Parameters::Risk
  include Parameters::Priority
  include ParameterSelector
  include Taggable

  acts_as_tree

  belongs_to :organization
  has_many :finding_review_assignments, dependent: :destroy, inverse_of: :finding
end
