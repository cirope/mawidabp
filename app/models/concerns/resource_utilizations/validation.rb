module ResourceUtilizations::Validation
  extend ActiveSupport::Concern

  included do
    validates :units, :resource, :resource_type, presence: true
    validates :units, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 9_999_999_999_999.99
    }, allow_nil: true, allow_blank: true
    validates :resource_id, uniqueness: {
      scope: [:resource_consumer_type, :resource_consumer_id, :resource_type]
    }
  end
end
