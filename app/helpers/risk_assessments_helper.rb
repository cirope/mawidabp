module RiskAssessmentsHelper
  def risk_score_items risk_weight
    risk_weight.risk_score_items.map { |rsi| [rsi.name, rsi.value] }
  end

  def risk_assessment_shared_icon risk_assessment
    title = t 'activerecord.attributes.risk_assessment.shared'
    icon  = icon 'fas', 'eye', title: title

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
        icon 'fas', 'list'
      end
    end
  end

  def heatmap_color heatmap, value
    if heatmap[:max] == value
      'bg-danger'
    elsif heatmap[:min] == value
      'bg-success'
    end
  end
end
