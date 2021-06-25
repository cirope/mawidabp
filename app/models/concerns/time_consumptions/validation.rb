module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    before_validation :set_limit

    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: :amount_limit
    }
  end

  private

    def set_limit
      self.limit = limit.to_i + amount_was.to_i
    end

    def amount_limit
      limit || 24
    end
end
