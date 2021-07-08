module TimeConsumptions::Validation
  extend ActiveSupport::Concern

  included do
    validates :date, presence: true, timeliness: { type: :date }
    validates :amount, presence: true, numericality: {
      greater_than: 0, less_than_or_equal_to: :amount_limit
    }
    validates :resource_id, uniqueness: { scope: [:user, :resource_type, :date] }
    validates :detail, presence: true, if: :require_detail?
  end

  def require_detail?
    resource.try(:require_detail)
  end

  private

    def amount_limit
      limit || 24.0
    end
end
