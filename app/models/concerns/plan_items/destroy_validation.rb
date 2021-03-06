module PlanItems::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    if review
      errors.add :base, 'Plan item is already related and can not be destroyed'

      false
    else
      true
    end
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
