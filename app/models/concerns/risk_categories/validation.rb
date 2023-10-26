module RiskCategories::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :name,
      pdf_encoding: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false },
      allow_nil: true, allow_blank: true
  end
end
