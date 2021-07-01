module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    before_validation :set_limit

    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: :amount_limit
    }
    validates :resource_on_id, :resource_on_type, presence: true
    validates :resource_on_id, uniqueness: { scope: [:user_id, :resource_on_type, :date] }
  end

  private

    def set_limit
      if !new_record?
        self.limit = limit.to_f + amount_was.to_f
      end
    end

    def amount_limit
      limit || 24.0
    end
end
