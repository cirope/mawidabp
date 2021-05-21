module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: :amount_limit
    }
  end

  private

    def amount_limit
      limit || 24
    end
end
