module WeaknessTemplates::Validations
  extend ActiveSupport::Concern

  included do
    before_validation :clean_array_attributes

    validates :title, :description, presence: true, pdf_encoding: true
    validates :title, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
  end

  private

    def clean_array_attributes
      self.impact = Array(impact).reject &:blank?
      self.operational_risk = Array(operational_risk).reject &:blank?
      self.internal_control_components =
        Array(internal_control_components).reject &:blank?
    end
end
