module RiskAssessmentsHelper
  def risk_weight_value_options
    RiskWeight.risks.map do |risk, value|
      [
        [value, t("risk_assessments.risk_weight_risks.#{risk}")].join(' - '),
        value
      ]
    end
  end

  def risk_assessment_shared_icon risk_assessment
    title = t 'activerecord.attributes.risk_assessment.shared'
    icon  = content_tag :span, nil, class: 'glyphicon glyphicon-eye-open',
                                    title: title

    risk_assessment.shared ? icon : ''
  end

  def should_fetch_risk_weights_for? risk_assessment_item
    is_valid = risk_assessment_item.errors.empty?
    risk_weights_are_unchanged = risk_assessment_item.risk_weights.all? do |rw|
      rw.persisted? && rw.errors.empty? && !rw.changed?
    end

    is_valid && risk_weights_are_unchanged
  end

  def link_to_create_plan risk_assessment
    if risk_assessment.final?
      options = {
        title: t('.merge_to_plan'),
        class: 'icon',
        data: {
          method:  :post,
          confirm: t('messages.confirmation')
        }
      }

      link_to [:merge_to_plan, risk_assessment], options do
        content_tag :span, nil, class: 'glyphicon glyphicon-list'
      end
    end
  end
end
