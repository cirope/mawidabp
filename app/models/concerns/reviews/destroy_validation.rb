module Reviews::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    !has_final_review? && control_objective_items.all?(&:can_be_destroyed?)
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
