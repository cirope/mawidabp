module Resources::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :name, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :name, uniqueness: { case_sensitive: false, scope: :resource_class }
    validates :cost_per_unit, numericality: { greater_than_or_equal_to: 0 },
      allow_nil: true
  end
end
