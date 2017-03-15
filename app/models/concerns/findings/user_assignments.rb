module Findings::UserAssignments
  extend ActiveSupport::Concern

  included do
    has_many :finding_user_assignments, dependent: :destroy, inverse_of: :finding,
      before_add:    :check_for_final_review,
      before_remove: :check_for_final_review
    has_many :users, -> { order(last_name: :asc) }, through: :finding_user_assignments

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
    finding_user_assignments.select(&:process_owner).map &:user
  end

  def responsible_auditors
    finding_user_assignments.responsibles.map &:user
  end
end
