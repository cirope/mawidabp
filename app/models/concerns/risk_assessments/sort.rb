module RiskAssessments::Sort
  extend ActiveSupport::Concern

  def sort_by_risk
    items = risk_assessment_items.reorder risk: :desc, order: :asc

    self.class.transaction do
      items.each_with_index do |rai, i|
        rai.update! order: i.next
      end
    end
  end
end
