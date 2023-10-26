module RiskRegistries::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :organization_id, :group_id, presence: true
    validates :name, pdf_encoding: true,
      length: { maximum: 255 }, allow_nil: true, allow_blank: true
    validates :organization_id, numericality: { only_integer: true },
      allow_blank: true, allow_nil: true
    validates :name, uniqueness: { case_sensitive: false, scope: :organization_id }
  end
end
