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

  def can_be_modified_by? user
    assignment_type = review_assignment_type user

    ReviewUserAssignment::TYPES.invert[assignment_type] != :auditor_read_only
  end

  private
    def review_assignment_type user
      assignment = user.review_user_assignments.where(review: self).take

      assignment&.assignment_type
    end
end
