module ResourceUtilizations::Validation
  extend ActiveSupport::Concern

  included do
    validates :units, :resource, :resource_type, presence: true
    validates :units, numericality: { greater_than_or_equal_to: 0 },
      allow_nil: true, allow_blank: true
  end
end
