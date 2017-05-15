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
end
