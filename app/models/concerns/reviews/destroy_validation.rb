module Reviews::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  def can_be_destroyed?
    !has_final_review? && control_objective_items.all?(&:can_be_destroyed?)
  end
end
