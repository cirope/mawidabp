module Findings::UserAssignments
  extend ActiveSupport::Concern

  included do
    has_many :finding_user_assignments, dependent: :destroy, inverse_of: :finding,
      before_add:    :check_for_final_review,
      before_remove: :check_for_final_review
    has_many :finding_owner_assignments, -> { owners }, foreign_key: :finding_id,
      class_name: 'FindingUserAssignment'
    has_many :finding_responsible_assignments, -> { responsibles }, foreign_key: :finding_id,
      class_name: 'FindingUserAssignment'
    has_many :users, -> { order(last_name: :asc) }, through: :finding_user_assignments
    has_many :users_that_can_act_as_audited,
      -> { can_act_as_audited },
      through: :finding_user_assignments, source: :user

    accepts_nested_attributes_for :finding_user_assignments, allow_destroy: true
  end

  def has_audited?
    finding_user_assignments.any? do |fua|
      fua.user.can_act_as_audited? && !fua.marked_for_destruction?
    end
  end

  def has_auditor?
    finding_user_assignments.any? do |fua|
      fua.user.auditor? && !fua.marked_for_destruction?
    end
  end

  def process_owners
    finding_owner_assignments.map &:user
  end

  def responsible_auditors
    finding_responsible_assignments.map &:user
  end

  def import_users
    if control_objective_item&.review
      control_objective_item.review.review_user_assignments.map do |rua|
        finding_user_assignments.build user_id: rua.user_id
      end
    end
  end
end
