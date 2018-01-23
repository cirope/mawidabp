module RiskAssessments::Plan
  extend ActiveSupport::Concern

  def create_plan
    plan = build_plan(
      period_id:       period_id,
      organization_id: organization_id
    )

    build_plan_items_for plan

    plan.save! && update_column(:plan_id, plan.id) && plan
  end

  private

    def build_plan_items_for plan
      risk_assessment_items.each_with_index do |risk_assessment_item, i|
        project       = "#{risk_assessment_item.name} (#{risk_assessment_item.risk})"
        risk_exposure = REVIEW_RISK_EXPOSURE.last if SHOW_REVIEW_EXTRA_ATTRIBUTES

        plan.plan_items.build(
          order_number:     i.next,
          project:          project,
          start:            period.start,
          end:              period.end,
          risk_exposure:    risk_exposure,
          business_unit_id: risk_assessment_item.business_unit_id
        )
      end
    end
end
