module RiskRegistries::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :group
    belongs_to :organization

    has_many :risk_categories, dependent: :destroy
    has_many :risks, through: :risk_categories

    accepts_nested_attributes_for :risk_categories, allow_destroy: true, reject_if: :all_blank
  end
end
