class Finding < ApplicationRecord
  include ActsAsTree
  include Auditable
  include Comparable
  include Findings::Achievements
  include Findings::Answers
  include Findings::Confirmation
  include Findings::Cost
  include Findings::CreateValidation
  include Findings::Csv
  include Findings::CustomAttributes
  include Findings::DateColumns
  include Findings::DestroyValidation
  include Findings::Expiration
  include Findings::FollowUpPDF
  include Findings::ImportantDates
  include Findings::JSON
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
  has_many :notification_relations, :as => :model, :dependent => :destroy
  has_many :notifications, -> { order(:created_at) },
    :through => :notification_relations
  has_many :comments, -> { order(:created_at => :asc) }, :as => :commentable,
    :dependent => :destroy
  has_many :finding_user_assignments, :dependent => :destroy,
    :inverse_of => :finding, :before_add => :check_for_final_review,
    :before_remove => :check_for_final_review
  has_many :finding_review_assignments, :dependent => :destroy,
    :inverse_of => :finding
  has_many :users, -> { order(:last_name => :asc) }, :through => :finding_user_assignments
  has_many :business_unit_findings, :dependent => :destroy
  has_many :business_units, :through => :business_unit_findings

  accepts_nested_attributes_for :comments, :allow_destroy => false
  accepts_nested_attributes_for :finding_user_assignments,
    :allow_destroy => true

  def initialize(attributes = nil, options = {}, import_users = false)
    super(attributes, options)

    if import_users && self.try(:control_objective_item).try(:review)
      self.control_objective_item.review.review_user_assignments.map do |rua|
        self.finding_user_assignments.build(:user_id => rua.user_id)
      end
    end

    if self.control_objective_item.try(:control)
      self.effect ||= self.control_objective_item.control.effects
    end

    self.state ||= STATUS[:incomplete]
    self.final ||= false
    self.finding_prefix ||= false
    self.origination_date ||= Time.zone.now.to_date
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

  def pending?
    PENDING_STATUS.include?(self.state)
  end

  def has_audited?
    finding_user_assignments.any? do |fua|
      !fua.marked_for_destruction? && fua.user.can_act_as_audited?
    end
  end

  def has_auditor?
    finding_user_assignments.any? do |fua|
      !fua.marked_for_destruction? && fua.user.auditor?
    end
  end

  def rescheduled?
    all_follow_up_dates.size > 0
  end

  def issue_date
    review.try(:conclusion_final_review).try(:issue_date)
  end

  def stale_confirmed_days
    parameter_in(organization_id, 'finding_stale_confirmed_days').to_i
  end

  def commitment_date
    finding_answers.where.not(commitment_date: nil).first&.commitment_date
  end

  def process_owners
    finding_user_assignments.select(&:process_owner).map(&:user)
  end

  def responsible_auditors
    self.finding_user_assignments.responsibles.map(&:user)
  end

  def all_follow_up_dates(end_date = nil, reload = false)
    @all_follow_up_dates = reload ? [] : (@all_follow_up_dates || [])

    if @all_follow_up_dates.empty?
      last_date = self.follow_up_date
      dates = self.versions_after_final_review(end_date).map do |v|
        v.reify(:has_one => false).try(:follow_up_date)
      end

      dates.each do |d|
        unless d.blank? || d == last_date
          @all_follow_up_dates << d
          last_date = d
        end
      end
    end

    @all_follow_up_dates.compact
  end
end
