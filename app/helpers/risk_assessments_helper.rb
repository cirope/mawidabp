module RiskAssessmentsHelper
  def risk_weight_value_options
    RiskWeight.risks.map do |risk, value|
      [
        [value, t("risk_assessments.risk_weight_risks.#{risk}")].join(' - '),
        value
      ]
    end
  end

  def should_fetch_risk_weights_for? risk_assessment_item
    is_valid = risk_assessment_item.errors.empty?
    risk_weights_are_unchanged = risk_assessment_item.risk_weights.all? do |rw|
      rw.persisted? && rw.errors.empty? && !rw.changed?
    end

    is_valid && risk_weights_are_unchanged
  end

  def link_to_create_plan risk_assessment
    if risk_assessment.draft? && risk_assessment.period.plan.blank?
      options = {
        title: t('.create_plan'),
        class: 'icon',
        data: {
          method:  :post,
          confirm: t('messages.confirmation')
        }
      }

      link_to [:create_plan, risk_assessment], options do
        content_tag :span, nil, class: 'glyphicon glyphicon-list'
      end
    end
  end
end
