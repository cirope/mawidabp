module PlanAndReviewApproval
  extend ActiveSupport::Concern

  def check_plan_and_review_approval object
    unless can_approve_plans_and_reviews?
      redirect_to object.model_name.plural.to_sym, alert: t('messages.not_allowed')
    end
  end

  private

    def can_approve_plans_and_reviews?
      can_perform?(:edit, :approval) &&
        Current.organization.require_plan_and_review_approval?
    end
end
