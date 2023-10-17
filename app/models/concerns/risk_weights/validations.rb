module RiskWeights::Validations
  extend ActiveSupport::Concern

  included do
    delegate :final?, to: :risk_assessment_item

    validates :value, presence: true, if: :final?
    validates :value, inclusion: {
      in: Proc.new { |rw| rw.risk_score_items.pluck :value }
    }, allow_blank: true
  end
end
