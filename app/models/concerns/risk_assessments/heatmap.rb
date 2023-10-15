module RiskAssessments::Heatmap
  extend ActiveSupport::Concern

  def build_heatmap
    hsh  = {}
    rwhs = risk_weights_heatmaps.to_a
    rwhx = rwhs.first
    rwhy = rwhs.last

    hsh[:body] = {}
    rwhx.risk_score_items.ordered.each do |rsix|
      hsh[:body][rsix.name] = []

      rwhy.risk_score_items.ordered.each do |rsiy|
        hsh[:body][rsix.name] << risk_weights_for(rsix, rsiy)
      end
    end

    hsh[:footer] = []
    rwhy.risk_score_items.ordered.each do |rsiy|
      hsh[:footer] << rsiy.name
    end

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
        'risk_assessment_item_id'
      ).where(
        'heatmap IS TRUE AND
        (risk_assessment_weight_id = :rawx_id AND value = :valuex) OR
        (risk_assessment_weight_id = :rawy_id AND value = :valuey)',
        rawx_id: rsix.risk_assessment_weight_id, valuex: rsix.value,
        rawy_id: rsiy.risk_assessment_weight_id, valuey: rsiy.value
      ).group(
        'risk_assessment_item_id'
      ).having(
        'count(*) = 2'
      )

      risk_assessment_items.where(id: rw_group).count
    end
end
