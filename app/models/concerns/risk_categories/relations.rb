module RiskCategories::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :risk_registry, optional: true

    has_many :risks, -> { order name: :asc }, dependent: :destroy

    accepts_nested_attributes_for :risks, allow_destroy: true,
      reject_if: :all_blank
  end
end
