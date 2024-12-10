module Reviews::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    !SHOW_REVIEW_AUTOMATIC_IDENTIFICATION &&
      !has_final_review? &&
      control_objective_items.all?(&:can_be_destroyed?) &&
      draft?
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
