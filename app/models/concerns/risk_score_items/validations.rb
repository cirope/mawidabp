module RiskScoreItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :value, presence: true
    validates :name, length: { maximum: 255 }, allow_blank: true
    validates :value, allow_blank: true, numericality: {
      greater_than_or_equal_to: 0
    }

    validate :uniqueness_name
  end

  private

    def uniqueness_name
      validate_uniqueness_for :name
    end

    def validate_uniqueness_for attr
      if send(attr).present?
        rsis = risk_assessment_weight.risk_score_items.reject do |rsi|
          rsi == self || rsi.marked_for_destruction?
        end

        if rsis.select { |rsi| rsi.send(attr).strip =~ /#{Regexp.quote(send(attr).strip)}/i }.any?
          errors.add attr, :taken
        end
      end
    end
end
