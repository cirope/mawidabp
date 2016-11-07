module PlanItems::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  def can_be_destroyed?
    if review
      errors.add :base, I18n.t('plan.errors.plan_item_related')

      false
    else
      true
    end
  end
end
