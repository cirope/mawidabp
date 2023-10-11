module RiskWeights::Validations
  extend ActiveSupport::Concern

  included do
    delegate :final?, to: :risk_assessment_item

    validates :identifier, presence: true
    validates :value, presence: true, if: :final?
    validates :value, inclusion: {
      in: Proc.new { |rw| rw.risk_score_items.pluck :value }
    }, allow_blank: true
    validates :identifier, length: { maximum: 255 }, allow_blank: true,
      uniqueness: {
        case_sensitive: false, scope: :risk_assessment_item_id
      }
  end
end
