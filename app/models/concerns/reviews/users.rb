module Reviews::Users
  extend ActiveSupport::Concern

  included do
    has_many :review_user_assignments, dependent: :destroy
    has_many :users, through: :review_user_assignments

    accepts_nested_attributes_for :review_user_assignments, allow_destroy: true
  end

  ReviewUserAssignment::TYPES.each do |type, _|
    define_method "has_#{type}?" do
      review_user_assignments.any? do |rua|
        rua.public_send("#{type}?") && !rua.marked_for_destruction?
      end
    end
  end

  def can_be_modified_by_current_user?
    can_be_modified = true

    if Current.organization.review_permission_by_assignment?
      assignment_type = review_assignment_type

      can_be_modified = [
        :auditor, :supervisor, :manager, :responsible
      ].include? ReviewUserAssignment::TYPES.invert[assignment_type]
    end

    can_be_modified
  end

  def user_assignments_readonly?
    return false unless Current.organization.require_plan_and_review_approval?

    manager_or_supervisor = [:manager, :supervisor].include?(
      ReviewUserAssignment::TYPES.invert[review_assignment_type]
    )

    approved? && !manager_or_supervisor
  end

  private

    def review_assignment_type
      if user = Current.user
        assignment = user.review_user_assignments.where(review: self).take

        assignment&.assignment_type
      end
    end
end
