module RiskAssessments::Heatmap
  extend ActiveSupport::Concern

  def build_heatmap
    hsh  = {}
    rwhs = risk_weights_heatmaps.to_a
    rwhx = rwhs.first
    rwhy = rwhs.last

    hsh[:body]   = {}
    hsh[:values] = []

    rwhx.risk_score_items.order(value: :desc).each do |rsix|
      values                = []
      hsh[:body][rsix.name] = []

      rwhy.risk_score_items.ordered.each do |rsiy|
        values << rsix.value + rsiy.value

        hsh[:body][rsix.name] << risk_weights_for(rsix, rsiy)
      end

      hsh[:values] << values
    end

    hsh[:footer] = []

    rwhy.risk_score_items.ordered.each do |rsiy|
      hsh[:footer] << rsiy.name
    end

    hsh[:total] = hsh[:values].flatten.max

    hsh
  end

  def risk_weights_heatmaps
    risk_assessment_weights.heatmaps
  end

  private

    def risk_weights_for rsix, rsiy
      rw_group = RiskWeight.joins(
        :risk_assessment_weight
      ).select(
        RiskAssessment.qcn 'risk_assessment_item_id'
      ).where(
        risk_assessment_weights: {
          heatmap: true,
          id: rsix.risk_assessment_weight_id
        },
        value: rsix.value
      ).or(
        RiskWeight.where(
          risk_assessment_weights: { id: rsiy.risk_assessment_weight_id },
          value: rsiy.value
        )
      ).group(
        RiskAssessment.qcn 'risk_assessment_item_id'
      ).having(
        'COUNT(*) = 2'
      )

      risk_assessment_items.where(id: rw_group).count
    end
end
