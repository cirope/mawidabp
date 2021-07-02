module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    before_validation :set_limit

    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: :amount_limit
    }
    validates :resource_id, uniqueness: { scope: [:user, :resource_type, :date] }
  end

  private

    def set_limit
      if persisted?
        self.limit = limit.to_f + amount_was.to_f
      end
    end

    def amount_limit
      limit || 24.0
    end
end
