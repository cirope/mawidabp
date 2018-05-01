module RiskAssessments::Plan
  extend ActiveSupport::Concern

  def merge_to_plan
    self.class.transaction do
      plan = period.plan || build_plan(
        period_id:       period_id,
        organization_id: organization_id
      )

      build_plan_items_for plan

      plan.allow_duplication = true

      plan.save! && update_columns(plan_id: plan.id, status: :merged) && plan
    end
  end

  private

    def build_plan_items_for plan
      risk_assessment_items.each_with_index do |risk_assessment_item, i|
        project       = "#{risk_assessment_item.name} (#{risk_assessment_item.risk})"
        risk_exposure = REVIEW_RISK_EXPOSURE.last if SHOW_REVIEW_EXTRA_ATTRIBUTES
        scope         = REVIEW_SCOPES.first       if SHOW_REVIEW_EXTRA_ATTRIBUTES

        plan.plan_items.build(
          order_number:     i.next,
          project:          project,
          start:            period.start,
          end:              period.end,
          scope:            scope,
          risk_exposure:    risk_exposure,
          business_unit_id: risk_assessment_item.business_unit_id
        )
      end
    end
end
