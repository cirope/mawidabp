module Plans::Permissions
  extend ActiveSupport::Concern

  def check_plan_permissions
    if @plan.approved?
      redirect_to plans_url, alert: t('messages.not_allowed')
    end
  end

  def check_plan_approval
    unless can_approve_plans_and_reviews?
      redirect_to plans_url, alert: t('messages.not_allowed')
    end
  end

  private

    def can_approve_plans_and_reviews?
      can_perform?(:edit, :approval) &&
        Current.organization.require_plan_and_review_approval?
    end
end
