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
  include Findings::DestroyValidation
  include Findings::Expiration
  include Findings::FollowUpDates
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

  def initialize(attributes = nil)
    super(attributes)

    if self.control_objective_item.try(:control)
      self.effect ||= self.control_objective_item.control.effects
    end

    self.state ||= STATUS[:incomplete]
    self.final ||= false
    self.finding_prefix ||= false
    self.origination_date ||= Time.zone.now.to_date
  end

  def import_users
    if self.try(:control_objective_item).try(:review)
      self.control_objective_item.review.review_user_assignments.map do |rua|
        self.finding_user_assignments.build(:user_id => rua.user_id)
      end
    end
  end

  def <=>(other)
    other.kind_of?(Finding) ? self.id <=> other.id : -1
  end

  def to_s
    "#{review_code} - #{title} - #{control_objective_item.try(:review)}"
  end

  alias_method :label, :to_s

  def informal
    text = "<strong>#{Finding.human_attribute_name(:title)}</strong>: "
    text << self.title.to_s
    text << "<br /><strong>#{Finding.human_attribute_name(:review_code)}</strong>: "
    text << self.review_code
    text << "<br /><strong>#{Review.model_name.human}</strong>: "
    text << self.control_objective_item.review.to_s
    text << "<br /><strong>#{Finding.human_attribute_name(:state)}</strong>: "
    text << self.state_text
    text << "<br /><strong>#{ControlObjectiveItem.human_attribute_name(:control_objective_text)}</strong>: "
    text << self.control_objective_item.to_s
  end

  def review_text
    self.control_objective_item.try(:review).try(:to_s)
  end

  def check_for_final_review(_)
    if self.final? && self.review && self.review.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def next_code(review = nil)
    raise 'Must be implemented in the subclasses'
  end

  def stale?
    being_implemented? && follow_up_date && follow_up_date < Date.today
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
