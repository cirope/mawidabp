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
    # o
    # users.where(finding_user_assignments: { process_owner: true }
    # o podemos armar una relacion que se llame owner_users... magic
    finding_user_assignments.owners.map &:user
  end

  def responsible_auditors
    finding_user_assignments.responsibles.map &:user
  end

  def import_users
    if control_objective_item&.review
      control_objective_item.review.review_user_assignments.map do |rua|
        finding_user_assignments.build user_id: rua.user_id
      end
    end
  end
end
