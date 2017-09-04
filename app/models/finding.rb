class Finding < ApplicationRecord
  include ActsAsTree
  include Auditable
  include Comparable
  include Findings::Achievements
  include Findings::Answers
  include Findings::BusinessUnits
  include Findings::Comments
  include Findings::Confirmation
  include Findings::Cost
  include Findings::CreateValidation
  include Findings::CSV
  include Findings::CustomAttributes
  include Findings::DateColumns
  include Findings::Defaults
  include Findings::DestroyValidation
  include Findings::Display
  include Findings::Expiration
  include Findings::FollowUp
  include Findings::FollowUpPDF
  include Findings::ImportantDates
  include Findings::JSON
  include Findings::Notifications
  include Findings::PDF
  include Findings::Reiterations
  include Findings::Relations
  include Findings::ReportScopes
  include Findings::ScaffoldNotifications
  include Findings::Scopes
  include Findings::Search
  include Findings::SortColumns
  include Findings::State
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

  cattr_accessor :current_user, :current_organization

  # Relaciones
  belongs_to :organization
  belongs_to :control_objective_item
  has_one :review, :through => :control_objective_item
  has_one :control_objective, :through => :control_objective_item
  has_many :finding_review_assignments, :dependent => :destroy,
    :inverse_of => :finding

  def <=>(other)
    other.kind_of?(Finding) ? self.id <=> other.id : -1
  end

  def to_s
    "#{review_code} - #{title} - #{control_objective_item.try(:review)}"
  end

  alias_method :label, :to_s

  def check_for_final_review(_)
    if self.final? && self.review && self.review.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def next_code(review = nil)
    raise 'Must be implemented in the subclasses'
  end

  def issue_date
    review.try(:conclusion_final_review).try(:issue_date)
  end

  def stale_confirmed_days
    parameter_in(organization_id, 'finding_stale_confirmed_days').to_i
  end

  def last_commitment_date
    finding_answers.
      where.not(commitment_date: nil).
      reorder(commitment_date: :desc).
      first&.commitment_date
  end
end
