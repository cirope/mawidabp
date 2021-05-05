module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: 24
    }
  end
end
