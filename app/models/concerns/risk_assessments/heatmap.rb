module RiskAssessments::Heatmap
  extend ActiveSupport::Concern

  def build_heatmap
    hsh  = {}
    rwhs = risk_weights_heatmaps.to_a
    rwhx = rwhs.first
    rwhy = rwhs.last

    hsh[:body] = {}
    rwhx.risk_score_items.each do |rsix|
      hsh[:body][rsix.name] = []

      rwhy.risk_score_items.each do |rsiy|
        hsh[:body][rsix.name] << risk_weights_for(rsix.value, rsiy.value)
      end
    end

    hsh[:footer] = []
    rwhy.risk_score_items.each do |rsiy|
      hsh[:footer] << rsiy.name
    end

    hsh[:max] = hsh[:body].values.flatten.max
    hsh[:min] = hsh[:body].values.flatten.min

    hsh
  end

  def risk_weights_heatmaps
    risk_assessment_weights.heatmaps
  end

  private

    def risk_weights_for valuex, valuey
      rw_group = RiskWeight.joins(:risk_assessment_weight).select('risk_assessment_item_id').where(
        'heatmap IS TRUE AND (value = :valuex OR value = :valuey)', valuex: valuex, valuey: valuey
      ).group('risk_assessment_item_id').having('count(*) = 2')

      risk_assessment_items.where(id: rw_group).count
    end
end
